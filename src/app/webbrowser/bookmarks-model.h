/*
 * Copyright 2013-2015 Canonical Ltd.
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

#ifndef __BOOKMARKS_MODEL_H__
#define __BOOKMARKS_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QList>
#include <QtCore/QSet>
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtSql/QSqlDatabase>

class BookmarksModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)

    Q_ENUMS(Roles)

public:
    BookmarksModel(QObject* parent=0);
    ~BookmarksModel();

    enum Roles {
        Url = Qt::UserRole + 1,
        Title,
        Icon,
        Created,
        Folder
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE bool contains(const QUrl& url) const;
    Q_INVOKABLE void add(const QUrl& url, const QString& title, const QUrl& icon, const QString& folder);
    Q_INVOKABLE void remove(const QUrl& url);

Q_SIGNALS:
    void databasePathChanged() const;
    void added(const QUrl& url) const;
    void removed(const QUrl& url) const;

private:
    QSqlDatabase m_database;

    struct BookmarkEntry {
        QUrl url;
        QString title;
        QUrl icon;
        QDateTime created;
        QString folder;
    };
    QSet<QUrl> m_urls;
    QList<BookmarkEntry> m_orderedEntries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void insertNewEntryInDatabase(const BookmarkEntry& entry);
    void removeExistingEntryFromDatabase(const QUrl& url);
};

#endif // __BOOKMARKS_MODEL_H__
