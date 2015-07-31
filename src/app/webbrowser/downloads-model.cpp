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

#include "downloads-model.h"

#include <QtCore/QDebug>
#include <QtSql/QSqlQuery>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>

#define CONNECTION_NAME "webbrowser-app-downloads"

/*!
    \class DownloadsModel
    \brief List model that stores information about downloaded files.

    DownloadsModel is a list model that stores information about files that
    have been downloaded by the browser and stored permanently 
    (e.g. in ~/Downloads), as opposed to those that were sent directly to
    another application after download. For each download the original URL, the
    path to the downloaded file, the file mimetype and the download time are 
    stored. The model is sorted chronologically to display the most recent 
    download first.

    The information is persistently stored on disk in a SQLite database.
    The database is read at startup to populate the model, and whenever a new
    entry is added to the model or an entry is removed from the model
    the database is updated. Removing a download from the model also results
    in it being deleted from the disk.
    The model doesn’t monitor the database for external changes, but does check
    that downloaded files still exist when first populating.
*/
DownloadsModel::DownloadsModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

DownloadsModel::~DownloadsModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void DownloadsModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_orderedEntries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
    Q_EMIT rowCountChanged();
}

void DownloadsModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS downloads "
                                  "(url VARCHAR, path VARCHAR, mimetype VARCHAR, "
                                  "created DATETIME DEFAULT CURRENT_TIMESTAMP);");
    createQuery.prepare(query);
    createQuery.exec();
}

void DownloadsModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT url, path, mimetype, created "
                                  "FROM downloads ORDER BY created DESC;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0;
    while (populateQuery.next()) {
        DownloadEntry entry;
        entry.url = populateQuery.value(0).toUrl();
        entry.path = populateQuery.value(1).toString();
        entry.mimetype = populateQuery.value(2).toString();
        entry.created = QDateTime::fromTime_t(populateQuery.value(3).toInt());

        // Only list an entry if its file exists, however we don't remove
        // the entry if the file is missing as it may be stored on a removable
        // medium like an SD card in the future, so could reappear.
        QFileInfo checkPath(entry.path);
        if (checkPath.exists()) {
            beginInsertRows(QModelIndex(), count, count);
            m_orderedEntries.append(entry);
            endInsertRows();
            ++count;
        }
    }
}

QHash<int, QByteArray> DownloadsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Path] = "path";
        roles[Mimetype] = "mimetype";
        roles[Created] = "created";
    }
    return roles;
}

int DownloadsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_orderedEntries.count();
}

QVariant DownloadsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const DownloadEntry& entry = m_orderedEntries.at(index.row());
    switch (role) {
    case Url:
        return entry.url;
    case Path:
        return entry.path;
    case Mimetype:
        return entry.mimetype;
    case Created:
        return entry.created;
    default:
        return QVariant();
    }
}

const QString DownloadsModel::databasePath() const
{
    return m_database.databaseName();
}

void DownloadsModel::setDatabasePath(const QString& path)
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
    Add a download to the database. This should be called after the download
    has completed successfully and been moved to its final location. Reporting
    of transfer progress prior to the download finishing is handled by the 
    ubuntu download manager and the transfer indicator.
*/
void DownloadsModel::add(const QUrl& url, const QString& path, const QString& mimetype)
{
    beginInsertRows(QModelIndex(), 0, 0);
    DownloadEntry entry;
    entry.url = url;
    entry.path = path;
    entry.mimetype = mimetype;
    entry.created = QDateTime::currentDateTime();
    m_orderedEntries.prepend(entry);
    endInsertRows();
    Q_EMIT added(url, path, mimetype);
    insertNewEntryInDatabase(entry);
    Q_EMIT rowCountChanged();
}

void DownloadsModel::insertNewEntryInDatabase(const DownloadEntry& entry)
{
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO downloads (url, "
                                                   "path, mimetype) "
                                                   "VALUES (?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.url.toString());
    query.addBindValue(entry.path);
    query.addBindValue(entry.mimetype);
    query.exec();
}

/*!
    Remove a downloaded file from the list of downloads and
    delete the file.
*/
void DownloadsModel::deleteDownload(const QString& path)
{
    int index = 0;
    Q_FOREACH(DownloadEntry entry, m_orderedEntries) {
        if (entry.path == path) {
            beginRemoveRows(QModelIndex(), index, index);
            m_orderedEntries.removeAt(index);
            endRemoveRows();
            Q_EMIT deleted(path);
            removeExistingEntryFromDatabase(path);
            Q_EMIT rowCountChanged();
            QFile::remove(path);
            return;
        } else {
            index++;
        }
    };
}

void DownloadsModel::removeExistingEntryFromDatabase(const QString& path)
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM downloads WHERE path=?;");
    query.prepare(deleteStatement);
    query.addBindValue(path);
    query.exec();
}
