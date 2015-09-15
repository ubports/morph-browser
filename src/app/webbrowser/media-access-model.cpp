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

#include "media-access-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "webbrowser-app-media-access"

/*!
    \class MediaAccessModel
    \brief List model that stores information about media access permissions

    MediaAccessModel is a list model that stores which permissions the user has
    already given, or denied, to websites for accessing audio or video input
    devices.

    The information is persistently stored on disk in a SQLite database.
    The database is read at startup to populate the model, and whenever a new
    entry is added to the model or an entry is removed from the model
    the database is updated.
    However the model doesn’t monitor the database for external changes.
*/
MediaAccessModel::MediaAccessModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

MediaAccessModel::~MediaAccessModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void MediaAccessModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_data.clear();
    m_ordered.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
    Q_EMIT rowCountChanged();
}

void MediaAccessModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS mediaAccess "
                                  "(origin VARCHAR, audio INTEGER, video INTEGER);");
    createQuery.prepare(query);
    createQuery.exec();
}

void MediaAccessModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT origin, audio, video FROM mediaAccess;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0;
    while (populateQuery.next()) {
        QUrl origin = populateQuery.value(0).toUrl();
        QBoolPair permissions;
        permissions.first = populateQuery.value(1).toInt() == 1; // audio
        permissions.second = populateQuery.value(2).toInt() == 1; // video

        beginInsertRows(QModelIndex(), count, count);
        m_data.insert(origin, permissions);
        m_ordered.append(origin);
        endInsertRows();
        ++count;
    }
}

QHash<int, QByteArray> MediaAccessModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Origin] = "origin";
        roles[Audio] = "audio";
        roles[Video] = "video";
    }
    return roles;
}

int MediaAccessModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_ordered.count();
}

QVariant MediaAccessModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    QUrl origin = m_ordered.at(index.row());
    if (role == Origin) {
        return QVariant::fromValue(origin);
    }
    else if (role == Audio || role == Video) {
        QBoolPair permissions = m_data.value(origin);
        return QVariant::fromValue(role == Audio ? permissions.first :
                                                   permissions.second);
    } else {
        return QVariant();
    }
}

QVariant MediaAccessModel::get(const QUrl& origin) const
{
    qDebug() << origin << m_data.contains(origin);
    if (m_data.contains(origin)) {
        QBoolPair permissions = m_data.value(origin);
        QVariantMap result;
        result.insert("origin", QVariant::fromValue(origin));
        result.insert("audio", QVariant::fromValue(permissions.first));
        result.insert("video", QVariant::fromValue(permissions.second));
        return result;
    } else {
        return QVariant();
    }
}

const QString MediaAccessModel::databasePath() const
{
    return m_database.databaseName();
}

void MediaAccessModel::setDatabasePath(const QString& path)
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

void MediaAccessModel::set(const QUrl& origin, bool audio, bool video)
{
    if (m_data.contains(origin)) {
        m_data.insert(origin, QBoolPair(audio, video));

        MediaAccessEntry entry;
        entry.origin = origin;
        entry.audio = audio;
        entry.video = video;
        updateExistingEntryInDatabase(entry);

        QVector<int> roles;
        roles << Audio;
        roles << Video;
        int index = m_ordered.indexOf(origin);
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), roles);
    } else {
        int end = m_ordered.count();
        beginInsertRows(QModelIndex(), end, end);
        m_data.insert(origin, QBoolPair(audio, video));
        m_ordered.append(origin);

        MediaAccessEntry entry;
        entry.origin = origin;
        entry.audio = audio;
        entry.video = video;
        insertNewEntryInDatabase(entry);

        endInsertRows();
        Q_EMIT rowCountChanged();
    }
}

void MediaAccessModel::insertNewEntryInDatabase(const MediaAccessEntry& entry)
{
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO mediaAccess "
                                                   "(origin, audio, video) "
                                                   "VALUES (?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.origin.toString());
    query.addBindValue(entry.audio ? 1 : 0);
    query.addBindValue(entry.video ? 1 : 0);
    query.exec();
}

void MediaAccessModel::remove(const QUrl& origin)
{
    if (m_data.contains(origin)) {
        int index = m_ordered.indexOf(origin);

        beginRemoveRows(QModelIndex(), index, index);
        m_ordered.removeAt(index);
        m_data.remove(origin);
        removeExistingEntryFromDatabase(origin);
        endRemoveRows();

        Q_EMIT rowCountChanged();
    } else {
        qWarning() << "Cannot remove origin because it is not present:" << origin;
    }
}

void MediaAccessModel::removeExistingEntryFromDatabase(const QUrl& origin)
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM mediaAccess WHERE origin=?;");
    query.prepare(deleteStatement);
    query.addBindValue(origin.toString());
    query.exec();
}

void MediaAccessModel::updateExistingEntryInDatabase(const MediaAccessEntry& entry)
{
    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE mediaAccess SET "
                                                   "audio=?, video=? "
                                                   "WHERE origin=?;");
    query.prepare(updateStatement);
    query.addBindValue(entry.audio ? 1 : 0);
    query.addBindValue(entry.video ? 1 : 0);
    query.addBindValue(entry.origin.toString());
    query.exec();
}
