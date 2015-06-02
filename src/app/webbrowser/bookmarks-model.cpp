/*
 * Copyright 2013-2014 Canonical Ltd.
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

#include "bookmarks-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "webbrowser-app-bookmarks"

/*!
    \class BookmarksModel
    \brief List model that stores information about bookmarked websites.

    BookmarksModel is a list model that stores bookmark entries for quick access
    to favourite websites. For a given URL, the following information is stored:
    page title and URL to the favorite icon if any.
    The model is sorted alphabetically at all times (by URL).

    The information is persistently stored on disk in a SQLite database.
    The database is read at startup to populate the model, and whenever a new
    entry is added to the model or an entry is removed from the model
    the database is updated.
    However the model doesn’t monitor the database for external changes.
*/
BookmarksModel::BookmarksModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

BookmarksModel::~BookmarksModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void BookmarksModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_urls.clear();
    m_orderedEntries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
    Q_EMIT rowCountChanged();
}

void BookmarksModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS bookmarks "
                                  "(url VARCHAR, title VARCHAR, icon VARCHAR, created INTEGER);");
    createQuery.prepare(query);
    createQuery.exec();

    // The first version of the database schema didn’t have a 'created' column
    QSqlQuery tableInfoQuery(m_database);
    query = QLatin1String("PRAGMA TABLE_INFO(bookmarks);");
    tableInfoQuery.prepare(query);
    tableInfoQuery.exec();
    while (tableInfoQuery.next()) {
        if (tableInfoQuery.value("name").toString() == "created") {
            break;
        }
    }
    if (!tableInfoQuery.isValid()) {
        QSqlQuery addCreatedColumnQuery(m_database);
        query = QLatin1String("ALTER TABLE bookmarks ADD COLUMN created INTEGER;");
        addCreatedColumnQuery.prepare(query);
        addCreatedColumnQuery.exec();
        // the default for the column is an empty value, which is interpreted as zero
        // when converted to a number. Zero represents a date far in the past, so
        // any newly created bookmark will correctly be represented as more recent than any other
    }
}

void BookmarksModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT url, title, icon, created "
                                  "FROM bookmarks ORDER BY created DESC;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0;
    while (populateQuery.next()) {
        BookmarkEntry entry;
        entry.url = populateQuery.value(0).toUrl();
        entry.title = populateQuery.value(1).toString();
        entry.icon = populateQuery.value(2).toUrl();
        entry.created = QDateTime::fromMSecsSinceEpoch(populateQuery.value(3).toULongLong());
        beginInsertRows(QModelIndex(), count, count);
        m_urls.insert(entry.url);
        m_orderedEntries.append(entry);
        endInsertRows();
        ++count;
    }
}

QHash<int, QByteArray> BookmarksModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Title] = "title";
        roles[Icon] = "icon";
        roles[Created] = "created";
    }
    return roles;
}

int BookmarksModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_orderedEntries.count();
}

QVariant BookmarksModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const BookmarkEntry& entry = m_orderedEntries.at(index.row());
    switch (role) {
    case Url:
        return entry.url;
    case Title:
        return entry.title;
    case Icon:
        return entry.icon;
    case Created:
        return entry.created;
    default:
        return QVariant();
    }
}

const QString BookmarksModel::databasePath() const
{
    return m_database.databaseName();
}

void BookmarksModel::setDatabasePath(const QString& path)
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

/*!
    Test if a given URL is already bookmarked.

    Return true if the model contains an entry with the same URL,
           false otherwise.
*/
bool BookmarksModel::contains(const QUrl& url) const
{
    return m_urls.contains(url);
}

/*!
    Add a given URL to the list of bookmarks.

    If the URL was previously bookmarked, do nothing.
*/
void BookmarksModel::add(const QUrl& url, const QString& title, const QUrl& icon)
{
    if (m_urls.contains(url)) {
        qWarning() << "URL already bookmarked:" << url;
    } else {
        beginInsertRows(QModelIndex(), 0, 0);
        BookmarkEntry entry;
        entry.url = url;
        entry.title = title;
        entry.icon = icon;
        entry.created = QDateTime::currentDateTime();
        m_urls.insert(url);
        m_orderedEntries.prepend(entry);
        endInsertRows();
        Q_EMIT added(url);
        insertNewEntryInDatabase(entry);
        Q_EMIT rowCountChanged();
    }
}

void BookmarksModel::insertNewEntryInDatabase(const BookmarkEntry& entry)
{
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO bookmarks (url, "
                                                   "title, icon, created) VALUES (?, ?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.url.toString());
    query.addBindValue(entry.title);
    query.addBindValue(entry.icon.toString());
    query.addBindValue(entry.created.toMSecsSinceEpoch());
    query.exec();
}

/*!
    Remove a given URL from the list of bookmarks.

    If the URL was not previously bookmarked, do nothing.
*/
void BookmarksModel::remove(const QUrl& url)
{
    if (m_urls.contains(url)) {
        int index = 0;
        Q_FOREACH(BookmarkEntry entry, m_orderedEntries) {
            if (entry.url == url) {
                beginRemoveRows(QModelIndex(), index, index);
                m_orderedEntries.removeAt(index);
                m_urls.remove(url);
                endRemoveRows();
                Q_EMIT removed(url);
                removeExistingEntryFromDatabase(url);
                Q_EMIT rowCountChanged();
                return;
            } else {
                index++;
            }
        };
    } else {
        qWarning() << "Invalid bookmark:" << url;
    }
}

void BookmarksModel::removeExistingEntryFromDatabase(const QUrl& url)
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM bookmarks WHERE url=?;");
    query.prepare(deleteStatement);
    query.addBindValue(url.toString());
    query.exec();
}
