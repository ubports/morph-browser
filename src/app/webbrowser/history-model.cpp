/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "domain-utils.h"
#include "history-model.h"

// Qt
#include <QtCore/QTimer>
#include <QtCore/QWriteLocker>
#include <QtSql/QSqlQuery>

#define SQL_DRIVER QStringLiteral("QSQLITE")
#define CONNECTION_NAME QStringLiteral("webbrowser-app-history")

/*!
    \class HistoryModel
    \brief List model that stores information about navigation history.

    HistoryModel is a list model that stores history entries that contain
    metadata about navigation history. For a given URL, the following
    information is stored: domain name, page title, URL to the favorite icon if
    any, total number of visits, and timestamp of the most recent visit (UTC).
    The model is sorted chronologically at all times (most recent visit first).

    The information is persistently stored on disk in a SQLite database.
    The database is read at startup to populate the model, and whenever a new
    entry is added to the model the database is updated.
    However the model doesn’t monitor the database for external changes.
    All database operations are performed on a separate thread in order not to
    block the UI thread.
*/
HistoryModel::HistoryModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_dbWorker = new DbWorker;
    m_dbWorker->moveToThread(&m_dbWorkerThread);
    connect(m_dbWorker, SIGNAL(hiddenEntryFetched(const QUrl&)),
            SLOT(onHiddenEntryFetched(const QUrl&)), Qt::QueuedConnection);
    connect(m_dbWorker,
            SIGNAL(entryFetched(const QUrl&, const QString&, const QString&,
                                const QUrl&, int, const QDateTime&)),
            SLOT(onEntryFetched(const QUrl&, const QString&, const QString&,
                                const QUrl&, int, const QDateTime&)),
            Qt::QueuedConnection);
    connect(m_dbWorker, SIGNAL(loaded()), SIGNAL(loaded()));
    m_dbWorkerThread.start(QThread::LowPriority);
}

HistoryModel::~HistoryModel()
{
    m_dbWorker->deleteLater();
    m_dbWorkerThread.quit();
    m_dbWorkerThread.wait();
}

void HistoryModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_hiddenEntries.clear();
    m_entries.clear();
    Q_EMIT m_dbWorker->resetDatabase(databaseName);
    endResetModel();
    Q_EMIT m_dbWorker->fetchEntries();
}

void HistoryModel::onHiddenEntryFetched(const QUrl& url)
{
    m_hiddenEntries.insert(url);
}

void HistoryModel::onEntryFetched(const QUrl& url, const QString& domain, const QString& title,
                                  const QUrl& icon, int visits, const QDateTime& lastVisit)
{
    HistoryEntry entry;
    entry.url = url;
    if (domain.isEmpty()) {
        entry.domain = DomainUtils::extractTopLevelDomainName(url);
    } else {
        entry.domain = domain;
    }
    entry.title = title;
    entry.icon = icon;
    entry.visits = visits;
    entry.lastVisit = lastVisit;
    entry.hidden = m_hiddenEntries.contains(url);
    int index = m_entries.count();
    beginInsertRows(QModelIndex(), index, index);
    m_entries.append(entry);
    endInsertRows();
}

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Domain] = "domain";
        roles[Title] = "title";
        roles[Icon] = "icon";
        roles[Visits] = "visits";
        roles[LastVisit] = "lastVisit";
        roles[LastVisitDate] = "lastVisitDate";
        roles[LastVisitDateString] = "lastVisitDateString";
        roles[Hidden] = "hidden";
    }
    return roles;
}

int HistoryModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant HistoryModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const HistoryEntry& entry = m_entries.at(index.row());
    switch (role) {
    case Url:
        return entry.url;
    case Domain:
        return entry.domain;
    case Title:
        return entry.title;
    case Icon:
        return entry.icon;
    case Visits:
        return entry.visits;
    case LastVisit:
        return entry.lastVisit;
    case LastVisitDate:
        return entry.lastVisit.toLocalTime().date();
    case LastVisitDateString:
        return entry.lastVisit.toLocalTime().date().toString(Qt::ISODate);
    case Hidden:
        return entry.hidden;
    default:
        return QVariant();
    }
}

const QString HistoryModel::databasePath() const
{
    return m_databasePath;
}

void HistoryModel::setDatabasePath(const QString& path)
{
    if (path != m_databasePath) {
        m_databasePath = path;
        if (path.isEmpty()) {
            resetDatabase(":memory:");
        } else {
            resetDatabase(path);
        }
        Q_EMIT databasePathChanged();
    }
}

int HistoryModel::getEntryIndex(const QUrl& url) const
{
    for (int i = 0; i < m_entries.count(); ++i) {
        if (m_entries.at(i).url == url) {
            return i;
        }
    }
    return -1;
}

/*!
    Add an entry to the model.

    If an entry with the same URL already exists, it is updated.
    Otherwise a new entry is created and added to the model.

    Return the total number of visits for the URL.
*/
int HistoryModel::add(const QUrl& url, const QString& title, const QUrl& icon)
{
    if (url.isEmpty()) {
        return 0;
    }
    int count = 1;
    QDateTime now = QDateTime::currentDateTimeUtc();
    int index = getEntryIndex(url);
    if (index == -1) {
        HistoryEntry entry;
        entry.url = url;
        entry.domain = DomainUtils::extractTopLevelDomainName(url);
        entry.title = title;
        entry.icon = icon;
        entry.visits = 1;
        entry.lastVisit = now;
        entry.hidden = m_hiddenEntries.contains(entry.url);
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        insertNewEntryInDatabase(entry);
        Q_EMIT rowCountChanged();
    } else {
        QVector<int> roles;
        roles << Visits;
        if (index == 0) {
            HistoryEntry& entry = m_entries.first();
            if (title != entry.title) {
                entry.title = title;
                roles << Title;
            }
            if (icon != entry.icon) {
                entry.icon = icon;
                roles << Icon;
            }
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                if (now.date() != entry.lastVisit.date()) {
                    roles << LastVisitDate;
                    roles << LastVisitDateString;
                }
                entry.lastVisit = now;
                roles << LastVisit;
            }
        } else {
            beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
            HistoryEntry entry = m_entries.takeAt(index);
            if (title != entry.title) {
                entry.title = title;
                roles << Title;
            }
            if (icon != entry.icon) {
                entry.icon = icon;
                roles << Icon;
            }
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                if (now.date() != entry.lastVisit.date()) {
                    roles << LastVisitDate;
                    roles << LastVisitDateString;
                }
                entry.lastVisit = now;
                roles << LastVisit;
            }
            m_entries.prepend(entry);
            endMoveRows();
        }
        Q_EMIT dataChanged(this->index(0, 0), this->index(0, 0), roles);
        updateExistingEntryInDatabase(m_entries.first());
    }
    return count;
}

/*!
    Update an existing entry in the model.

    If no entry with the same URL exists yet, do nothing (and return false).
    Otherwise the title and icon of the existing entry are updated (the number
    of visits remains unchanged).

    Return true if an update actually happened, false otherwise.
*/
bool HistoryModel::update(const QUrl& url, const QString& title, const QUrl& icon)
{
    if (url.isEmpty()) {
        return false;
    }
    int index = getEntryIndex(url);
    if (index == -1) {
        return false;
    }
    QVector<int> roles;
    const HistoryEntry& entry = m_entries.at(index);
    if (title != entry.title) {
        m_entries[index].title = title;
        roles << Title;
    }
    if (icon != entry.icon) {
        m_entries[index].icon = icon;
        roles << Icon;
    }
    if (roles.isEmpty()) {
        return false;
    }
    Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), roles);
    updateExistingEntryInDatabase(entry);
    return true;
}

/*!
    Remove a given URL from the history model.

    If the URL was not previously visited, do nothing.
*/
void HistoryModel::removeEntryByUrl(const QUrl& url)
{
    if (url.isEmpty()) {
        return;
    }

    removeByIndex(getEntryIndex(url));
    removeEntryFromDatabaseByUrl(url);
    Q_EMIT rowCountChanged();
}

/*!
    Remove all urls last visited in a given DATE from the history model.
*/
void HistoryModel::removeEntriesByDate(const QDate& date)
{
    if (!date.isValid()) {
        return;
    }

    for (int i = m_entries.count() - 1; i >= 0; --i) {
        if (m_entries.at(i).lastVisit.toLocalTime().date() == date) {
            removeByIndex(i);
        }
    }
    removeEntriesFromDatabaseByDate(date);
    Q_EMIT rowCountChanged();
}

/*!
    Remove all urls from a given DOMAIN from the history model.
*/
void HistoryModel::removeEntriesByDomain(const QString& domain)
{
    if (domain.isEmpty()) {
        return;
    }

    for (int i = m_entries.count() - 1; i >= 0; --i) {
        if (m_entries.at(i).domain == domain) {
            removeByIndex(i);
        }
    }
    removeEntriesFromDatabaseByDomain(domain);
    Q_EMIT rowCountChanged();
}

void HistoryModel::removeByIndex(int index)
{
    if (index >= 0) {
        beginRemoveRows(QModelIndex(), index, index);
        m_entries.removeAt(index);
        endRemoveRows();
    }
}

void HistoryModel::insertNewEntryInDatabase(const HistoryEntry& entry)
{
    QVariantList values;
    values << entry.url.toString();
    values << entry.domain;
    values << entry.title;
    values << entry.icon.toString();
    values << entry.lastVisit.toTime_t();
    Q_EMIT m_dbWorker->enqueue(DbWorker::InsertNewEntry, values);
}

void HistoryModel::insertNewEntryInHiddenDatabase(const QUrl& url)
{
    Q_EMIT m_dbWorker->enqueue(DbWorker::InsertNewHiddenEntry, QVariantList() << url.toString());
}

void HistoryModel::updateExistingEntryInDatabase(const HistoryEntry& entry)
{
    QVariantList values;
    values << entry.domain;
    values << entry.title;
    values << entry.icon.toString();
    values << entry.visits;
    values << entry.lastVisit.toTime_t();
    values << entry.url.toString();
    Q_EMIT m_dbWorker->enqueue(DbWorker::UpdateExistingEntry, values);
}

void HistoryModel::removeEntryFromDatabaseByUrl(const QUrl& url)
{
    Q_EMIT m_dbWorker->enqueue(DbWorker::RemoveEntryByUrl, QVariantList() << url.toString());
}

void HistoryModel::removeEntryFromHiddenDatabaseByUrl(const QUrl& url)
{
    Q_EMIT m_dbWorker->enqueue(DbWorker::RemoveHiddenEntryByUrl, QVariantList() << url.toString());
}

void HistoryModel::removeEntriesFromDatabaseByDate(const QDate& date)
{
    QVariantList values;
    QDateTime dateTime = QDateTime(date);
    values << dateTime.toTime_t();
    dateTime.setTime(QTime(23, 59, 59, 999));
    values << dateTime.toTime_t();
    Q_EMIT m_dbWorker->enqueue(DbWorker::RemoveEntriesByDate, values);
}

void HistoryModel::removeEntriesFromDatabaseByDomain(const QString& domain)
{
    Q_EMIT m_dbWorker->enqueue(DbWorker::RemoveEntriesByDomain, QVariantList() << domain);
}

void HistoryModel::clearAll()
{
    if (!m_entries.isEmpty()) {
        beginResetModel();
        m_hiddenEntries.clear();
        m_entries.clear();
        endResetModel();
        clearDatabase();
        Q_EMIT rowCountChanged();
    }
}

void HistoryModel::clearDatabase()
{
    Q_EMIT m_dbWorker->enqueue(DbWorker::Clear, QVariantList() << QStringLiteral("history"));
    Q_EMIT m_dbWorker->enqueue(DbWorker::Clear, QVariantList() << QStringLiteral("history_hidden"));
}

/*!
    Mark an entry in the model as hidden.

    Add a new entry to the hidden list.
    If an entry with the URL exists, it is updated.
*/
void HistoryModel::hide(const QUrl& url)
{
    if (url.isEmpty() || m_hiddenEntries.contains(url)) {
        return;
    }

    m_hiddenEntries.insert(url);

    QVector<int> roles;
    roles << Hidden;

    for (int i = 0; i < m_entries.count(); ++i) {
        HistoryEntry& entry = m_entries[i];
        if (entry.url == url) {
            entry.hidden = true;
            Q_EMIT dataChanged(this->index(i, 0), this->index(i, 0), roles);
        }
    }                                                                   

    insertNewEntryInHiddenDatabase(url);
}

/*!
    Mark an entry in the model as not hidden.

    If an entry with the URL exists on the hidden entries, it is removed.
    If an entry with the URL exists, it is updated.
*/
void HistoryModel::unHide(const QUrl& url)
{
    if (url.isEmpty() || !m_hiddenEntries.contains(url)) {
        return;
    }

    m_hiddenEntries.remove(url);

    QVector<int> roles;
    roles << Hidden;

    for (int i = 0; i < m_entries.count(); ++i) {
        HistoryEntry& entry = m_entries[i];
        if (entry.url == url) {
            entry.hidden = false;
            Q_EMIT dataChanged(this->index(i, 0), this->index(i, 0), roles);
        }
    }                                                                   

    removeEntryFromHiddenDatabaseByUrl(url);
}

QVariantMap HistoryModel::get(int i) const
{
    QVariantMap item;
    QHash<int, QByteArray> roles = roleNames();

    QModelIndex modelIndex = index(i, 0);
    if (modelIndex.isValid()) {
        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            item.insert(roleName, data(modelIndex, role));
        }
    }
    return item;
}

DbWorker::DbWorker()
    : QObject()
    , m_flush(nullptr)
{
    // Ensure all database operations are performed on the same thread
    connect(this, SIGNAL(resetDatabase(const QString&)),
            SLOT(doResetDatabase(const QString&)), Qt::QueuedConnection);
    connect(this, SIGNAL(fetchEntries()),
            SLOT(doFetchEntries()), Qt::QueuedConnection);
    qRegisterMetaType<Operation>("Operation");
    connect(this, SIGNAL(enqueue(Operation, QVariantList)),
            SLOT(doEnqueue(Operation, QVariantList)), Qt::QueuedConnection);
}

DbWorker::~DbWorker()
{
    if (m_flush) {
        m_flush->stop();
        delete m_flush;
        m_flush = nullptr;
    }
    doFlush();
    if (m_database.isOpen()) {
        m_database.close();
    }
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void DbWorker::doResetDatabase(const QString& databaseName)
{
    if (m_flush) {
        m_flush->stop();
        delete m_flush;
        m_flush = nullptr;
    }
    doFlush();
    if (m_database.isOpen()) {
        m_database.close();
    }
    if (!m_database.isValid()) {
         m_database = QSqlDatabase::addDatabase(SQL_DRIVER, CONNECTION_NAME);
    }
    m_database.setDatabaseName(databaseName);
    m_database.open();
    doCreateOrAlterDatabaseSchema();
}

void DbWorker::doCreateOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QStringLiteral("CREATE TABLE IF NOT EXISTS history "
                                   "(url VARCHAR, domain VARCHAR, title VARCHAR,"
                                   " icon VARCHAR, visits INTEGER, lastVisit DATETIME);");
    createQuery.prepare(query);
    createQuery.exec();

    // The first version of the database schema didn't have a 'domain' column
    QSqlQuery tableInfoQuery(m_database);
    query = QStringLiteral("PRAGMA TABLE_INFO(history);");
    tableInfoQuery.prepare(query);
    tableInfoQuery.exec();
    while (tableInfoQuery.next()) {
        if (tableInfoQuery.value(QStringLiteral("name")).toString() == QStringLiteral("domain")) {
            break;
        }
    }
    if (!tableInfoQuery.isValid()) {
        QSqlQuery addDomainColumnQuery(m_database);
        query = QStringLiteral("ALTER TABLE history ADD COLUMN domain VARCHAR;");
        addDomainColumnQuery.prepare(query);
        addDomainColumnQuery.exec();
        // Updating all the entries in the database to add the domain is a
        // costly operation that would slow down the application startup,
        // do not do it here.
    }

    QSqlQuery createHiddenQuery(m_database);
    query = QStringLiteral("CREATE TABLE IF NOT EXISTS history_hidden (url VARCHAR);");
    createHiddenQuery.prepare(query);
    createHiddenQuery.exec();
}

void DbWorker::doFetchEntries()
{
    QSqlQuery populateHiddenQuery(m_database);
    QString query = QStringLiteral("SELECT url FROM history_hidden;");
    populateHiddenQuery.prepare(query);
    populateHiddenQuery.exec();
    while (populateHiddenQuery.next()) {
        Q_EMIT hiddenEntryFetched(populateHiddenQuery.value(0).toUrl());
    }

    QSqlQuery populateQuery(m_database);
    query = QStringLiteral("SELECT url, domain, title, icon, visits, lastVisit "
                           "FROM history ORDER BY lastVisit DESC;");
    populateQuery.prepare(query);
    populateQuery.exec();
    while (populateQuery.next()) {
        Q_EMIT entryFetched(populateQuery.value(0).toUrl(),
                            populateQuery.value(1).toString(),
                            populateQuery.value(2).toString(),
                            populateQuery.value(3).toUrl(),
                            populateQuery.value(4).toInt(),
                            QDateTime::fromTime_t(populateQuery.value(5).toInt()));
    }
    Q_EMIT loaded();
}

void DbWorker::doEnqueue(DbWorker::Operation operation, QVariantList values)
{
    if (!m_flush) {
        m_flush = new QTimer;
        m_flush->setInterval(1000);
        m_flush->setSingleShot(true);
        connect(m_flush, SIGNAL(timeout()), SLOT(doFlush()));
    }
    QWriteLocker locker(&m_lock);
    m_pending.enqueue(qMakePair(operation, values));
    m_flush->start();
}

void DbWorker::doFlush()
{
    QWriteLocker locker(&m_lock);
    while (!m_pending.isEmpty()) {
        QPair<Operation, QVariantList> args = m_pending.dequeue();
        QString statement;
        switch (args.first) {
        case InsertNewEntry:
            statement = QStringLiteral("INSERT INTO history (url, domain, title, icon, "
                                       "visits, lastVisit) VALUES (?, ?, ?, ?, 1, ?);");
            break;
        case InsertNewHiddenEntry:
            statement = QStringLiteral("INSERT INTO history_hidden (url) VALUES (?);");
            break;
        case UpdateExistingEntry:
            statement = QStringLiteral("UPDATE history SET domain=?, title=?, icon=?, "
                                       "visits=?, lastVisit=? WHERE url=?;");
            break;
        case RemoveEntryByUrl:
            statement = QStringLiteral("DELETE FROM history WHERE url=?;");
            break;
        case RemoveHiddenEntryByUrl:
            statement = QStringLiteral("DELETE FROM history_hidden WHERE url=?;");
            break;
        case RemoveEntriesByDate:
            statement = QStringLiteral("DELETE FROM history WHERE lastVisit BETWEEN ? AND ?;");
            break;
        case RemoveEntriesByDomain:
            statement = QStringLiteral("DELETE FROM history WHERE domain=?;");
            break;
        case Clear:
            statement = QStringLiteral("DELETE FROM %1;").arg(args.second.takeFirst().toString());
            break;
        default:
            Q_UNREACHABLE();
        }
        if (statement.isEmpty()) {
            return;
        }
        QSqlQuery query(m_database);
        if (!query.prepare(statement)) {
            continue;
        }
        Q_FOREACH(const QVariant& value, args.second) {
            query.addBindValue(value);
        }
        query.exec();
    }
}
