/*
 * Copyright 2015 Canonical Ltd.
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

#ifndef __DOWNLOADS_MODEL_H__
#define __DOWNLOADS_MODEL_H__

#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QList>
#include <QtCore/QSet>
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtSql/QSqlDatabase>

class DownloadsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    DownloadsModel(QObject* parent=0);
    ~DownloadsModel();

    enum Roles {
        DownloadId = Qt::UserRole + 1,
        Url,
        Path,
        Filename,
        Extension,
        Mimetype,
        Progress,
        Complete,
        Error,
        Created
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE void add(const QString &downloadId, const QUrl& url, const QString& mimetype);
    Q_INVOKABLE void moveToDownloads(const QString& downloadId, const QString& path);
    Q_INVOKABLE void setPath(const QString& downloadId, const QString& path);
    Q_INVOKABLE void setProgress(const QString& downloadId, const int progress);
    Q_INVOKABLE void setComplete(const QString& downloadId, const bool complete);
    Q_INVOKABLE void setError(const QString& downloadId, const QString& error);
    Q_INVOKABLE void deleteDownload(const QString& path);
    Q_INVOKABLE QString iconForMimetype(const QString& mimetypeString);
    Q_INVOKABLE QString nameForMimetype(const QString& mimetypeString);

Q_SIGNALS:
    void databasePathChanged() const;
    void added(const QString& downloadId, const QUrl& url, const QString& mimetype) const;
    void pathChanged(const QString& downloadId, const QString& path) const;
    void progressChanged(const QString& downloadId, const int progress) const;
    void completeChanged(const QString& downloadId, const bool complete) const;
    void errorChanged(const QString& downloadId, const QString& error) const;
    void deleted(const QString& path) const;
    void rowCountChanged();

private:
    QSqlDatabase m_database;

    struct DownloadEntry {
        QString downloadId;
        QUrl url;
        QString path;
        QString filename;
        QString extension;
        QString mimetype;
        int progress;
        bool complete;
        QString error;
        QDateTime created;
    };
    QList<DownloadEntry> m_orderedEntries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void insertNewEntryInDatabase(const DownloadEntry& entry);
    void removeExistingEntryFromDatabase(const QString& path);
};

#endif // __DOWNLOADS_MODEL_H__
