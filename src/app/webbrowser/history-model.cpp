/*
 * Copyright 2013 Canonical Ltd.
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
#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "webbrowser-app-history"

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
*/
HistoryModel::HistoryModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

HistoryModel::~HistoryModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void HistoryModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_entries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
}

void HistoryModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS history "
                                  "(url VARCHAR, domain VARCHAR, title VARCHAR,"
                                  " icon VARCHAR, visits INTEGER, lastVisit DATETIME);");
    createQuery.prepare(query);
    createQuery.exec();

    // The first version of the database schema didn’t have a 'domain' column
    QSqlQuery tableInfoQuery(m_database);
    query = QLatin1String("PRAGMA TABLE_INFO(history);");
    tableInfoQuery.prepare(query);
    tableInfoQuery.exec();
    while (tableInfoQuery.next()) {
        if (tableInfoQuery.value("name").toString() == "domain") {
            break;
        }
    }
    if (!tableInfoQuery.isValid()) {
        QSqlQuery addDomainColumnQuery(m_database);
        query = QLatin1String("ALTER TABLE history ADD COLUMN domain VARCHAR;");
        addDomainColumnQuery.prepare(query);
        addDomainColumnQuery.exec();
        // Updating all the entries in the database to add the domain is a
        // costly operation that would slow down the application startup,
        // do not do it here.
    }
}

void HistoryModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT url, domain, title, icon, visits, lastVisit "
                                  "FROM history ORDER BY lastVisit DESC;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0;
    while (populateQuery.next()) {
        HistoryEntry entry;
        entry.url = populateQuery.value(0).toUrl();
        entry.domain = populateQuery.value(1).toString();
        if (entry.domain.isEmpty()) {
            entry.domain = DomainUtils::extractTopLevelDomainName(entry.url);
        }
        entry.title = populateQuery.value(2).toString();
        entry.icon = populateQuery.value(3).toUrl();
        entry.visits = populateQuery.value(4).toInt();
        entry.lastVisit = QDateTime::fromTime_t(populateQuery.value(5).toInt());
        beginInsertRows(QModelIndex(), count, count);
        m_entries.append(entry);
        endInsertRows();
        ++count;
    }
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
    default:
        return QVariant();
    }
}

const QString HistoryModel::databasePath() const
{
    return m_database.databaseName();
}

void HistoryModel::setDatabasePath(const QString& path)
{
    if (path != databasePath()) {
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
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        insertNewEntryInDatabase(entry);
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

void HistoryModel::insertNewEntryInDatabase(const HistoryEntry& entry)
{
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO history (url, domain, title, icon, "
                                                   "visits, lastVisit) VALUES (?, ?, ?, ?, 1, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.url.toString());
    query.addBindValue(entry.domain);
    query.addBindValue(entry.title);
    query.addBindValue(entry.icon.toString());
    query.addBindValue(entry.lastVisit.toTime_t());
    query.exec();
}

void HistoryModel::updateExistingEntryInDatabase(const HistoryEntry& entry)
{
    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE history SET domain=?, title=?, icon=?, "
                                                   "visits=?, lastVisit=? WHERE url=?;");
    query.prepare(updateStatement);
    query.addBindValue(entry.domain);
    query.addBindValue(entry.title);
    query.addBindValue(entry.icon.toString());
    query.addBindValue(entry.visits);
    query.addBindValue(entry.lastVisit.toTime_t());
    query.addBindValue(entry.url.toString());
    query.exec();
}

void HistoryModel::clearAll()
{
    if (!m_entries.isEmpty()) {
        beginResetModel();
        m_entries.clear();
        endResetModel();
        clearDatabase();
    }
}

void HistoryModel::clearDatabase()
{
    QSqlQuery query(m_database);
    QString deleteStatement = QLatin1String("DELETE FROM history;");
    query.prepare(deleteStatement);
    query.exec();
}
