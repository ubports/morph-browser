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

    Each row in the model represents an origin domain for which at least one
    permission has been set, represented by the roles \a MediaAccessModel::Audio
    and \a MediaAccessModel::Video. These roles will contain true if permission
    has been granted to the origin, false if it has been denied, and undefined
    if no choice has been made by the user yet.

    To simplify filtering using a QSortFilterProxyModel, an additional string
    role is provided for each row: \a MediaAccessModel::PermissionsSet
    This role will contain "a" if the audio permission has been set (i.e. either
    granted or denied), "v" if the video permission has been set, and
    "av" if both have been set.

    The information is persistently stored on disk in a SQLite database.
    The database is read at startup to populate the model, and whenever a new
    entry is added to the model or an entry is removed from the model
    the database is updated.
    However the model doesn’t monitor the database for external changes. For
    this reason it is recommended to instantiate it as a singleton in the app.
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

QHash<int, QByteArray> MediaAccessModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Origin] = "origin";
        roles[Audio] = "audio";
        roles[Video] = "video";
        roles[PermissionsSet] = "permissionsSet";
    }
    return roles;
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
        QString origin = populateQuery.value(0).toString();
        Permissions permissions;
        permissions.audio = static_cast<PermissionValue>(qBound(0, populateQuery.value(1).toInt(), 2));
        permissions.video = static_cast<PermissionValue>(qBound(0, populateQuery.value(2).toInt(), 2));

        beginInsertRows(QModelIndex(), count, count);
        m_data.insert(origin, permissions);
        m_ordered.append(origin);
        endInsertRows();
        ++count;
    }
}

int MediaAccessModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_data.count();
}

QVariant MediaAccessModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    QString origin = m_ordered.at(index.row());
    if (role == Origin) {
        return QVariant::fromValue(origin);
    }
    else if (role == PermissionsSet) {
        Permissions permissions = m_data.value(origin);
        QString permissionsSet;
        if (permissions.audio != Unset) permissionsSet.append('a');
        if (permissions.video != Unset) permissionsSet.append('v');
        return QVariant::fromValue(permissionsSet);
    } else if (role == Audio || role == Video) {
        Permissions permissions = m_data.value(origin);
        int value = (role == Audio) ? permissions.audio : permissions.video;
        if (value == PermissionValue::Unset) return QVariant();
        else return QVariant::fromValue((bool)(value == PermissionValue::Allow));
    } else {
        return QVariant();
    }
}

/*!
 * \qmlmethod void get(url origin)
 * Retrieve access permissions for \a origin.
 *
 * An object is returned with "audio" and "video" properties set to the bool
 * value of the corresponding media access permission.
 * If the specified permission is currently unset for the \a origin then its
 * value will be undefined.
 */
QVariant MediaAccessModel::get(const QString& origin) const
{
    QVariantMap result;
    if (m_data.contains(origin)) {
        Permissions permissions = m_data.value(origin);
        result.insert("audio", permissions.audio == PermissionValue::Unset ? QVariant() :
                               QVariant::fromValue(permissions.audio == PermissionValue::Allow));
        result.insert("video", permissions.video == PermissionValue::Unset ? QVariant() :
                               QVariant::fromValue(permissions.video == PermissionValue::Allow));
        return result;
    } else {
        result.insert("audio", QVariant());
        result.insert("video", QVariant());
    }
    return result;
}

bool isNullOrUndefined(const QVariant& value)
{
    return !value.isValid() || value.isNull() ||
           (QMetaType::VoidStar == static_cast<QMetaType::Type>(value.type()) &&
            value.toInt() == 0);
}

/*!
 * \qmlmethod void set(url origin, var audio, var video)
 * Set access permissions for \a origin.
 *
 * If \a audio or \a video are set to any other than null or undefined,
 * then the respective permission record is updated with the result of
 * converting the value to a boolean.
 * If either is set to null or to undefined, then the respective permission
 * record will not be modified at all and will retain its present value.
 *
 * If there is no record currently set for the \a origin, a new record is
 * created, unless both \a audio and \a video are null or undefined.
 */
void MediaAccessModel::set(const QString& origin, const QVariant& audio, const QVariant& video)
{
    if (isNullOrUndefined(audio) && isNullOrUndefined(video)) {
        return;
    }

    if (m_data.contains(origin)) {
        QVector<int> rolesChanged;
        rolesChanged << PermissionsSet;

        Permissions permissions = m_data.value(origin);
        if (!isNullOrUndefined(audio)) {
            permissions.audio = audio.toBool() ? Allow : Deny;
            updateExistingEntryInDatabase(origin, AudioPermission, permissions.audio);
            rolesChanged << Audio;
        }
        if (!isNullOrUndefined(video)) {
            permissions.video = video.toBool() ? Allow : Deny;
            updateExistingEntryInDatabase(origin, VideoPermission, permissions.video);
            rolesChanged << Video;
        }

        m_data.insert(origin, permissions);
        int index = m_ordered.indexOf(origin);
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), rolesChanged);
    } else {
        int end = m_ordered.count();
        beginInsertRows(QModelIndex(), end, end);
        Permissions permissions = m_data.value(origin);
        permissions.audio = (isNullOrUndefined(audio)) ? Unset :
                            (audio.toBool() ? Allow : Deny);
        permissions.video = (isNullOrUndefined(video)) ? Unset :
                            (video.toBool() ? Allow : Deny);

        m_data.insert(origin, permissions);
        m_ordered.append(origin);

        insertNewEntryInDatabase(origin, permissions);
        endInsertRows();
        Q_EMIT rowCountChanged();
    }
}

/*!
* \qmlmethod void set(url origin, bool unsetAudio, bool unsetVideo)
* Unset access permissions for \a origin.
*
* If either \a unsetAudio or \a unsetVideo are true, the respective permission
* record will be updated so that the permission will result unset (usually
* causing the application to issue a new prompt to the user the next time access
* is attempted to the media resource that was unset for \a origin)
*
* If this call causes both permissions to become unset, the record gets removed
* entirely from the model.
*/
void MediaAccessModel::unset(const QString& origin, bool unsetAudio, bool unsetVideo)
{
    if (!(unsetAudio || unsetVideo)) {
        return;
    }

    if (m_data.contains(origin)) {
        Permissions permissions = m_data.value(origin);
        if ((unsetAudio && unsetVideo) ||
            (unsetAudio && permissions.video == Unset) ||
            (unsetVideo && permissions.audio == Unset)) {
            // if all permissions are going to be unset then remove the row from
            // the database entirely
            int index = m_ordered.indexOf(origin);
            beginRemoveRows(QModelIndex(), index, index);
            m_ordered.removeAt(index);
            m_data.remove(origin);
            removeExistingEntryFromDatabase(origin);
            endRemoveRows();

            Q_EMIT rowCountChanged();
        } else {
            QVector<int> rolesChanged;
            rolesChanged << PermissionsSet;
            if (unsetAudio) {
                permissions.audio = Unset;
                updateExistingEntryInDatabase(origin, AudioPermission, Unset);
                rolesChanged << Audio;
            }
            if (unsetVideo) {
                permissions.video = Unset;
                updateExistingEntryInDatabase(origin, VideoPermission, Unset);
                rolesChanged << Video;
            }

            m_data.insert(origin, permissions);
            int index = m_ordered.indexOf(origin);
            Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), rolesChanged);
        }
    }
}

void MediaAccessModel::insertNewEntryInDatabase(const QString& origin,
                                                const Permissions& permissions)
{
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO mediaAccess "
                                                   "(origin, audio, video) "
                                                   "VALUES (?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(origin);
    query.addBindValue((int) permissions.audio);
    query.addBindValue((int) permissions.video);
    query.exec();
}

void MediaAccessModel::updateExistingEntryInDatabase(const QString& origin,
                                                     PermissionType which, PermissionValue value)
{
    QSqlQuery query(m_database);
    static QString audioUpdateStatement = QLatin1String("UPDATE mediaAccess SET "
                                                        "audio = ? WHERE origin=?;");
    static QString videoUpdateStatement = QLatin1String("UPDATE mediaAccess SET "
                                                        "video = ? WHERE origin=?;");

    const QString& statement = (which == AudioPermission) ? audioUpdateStatement
                                                          : videoUpdateStatement;
    query.prepare(statement);
    query.addBindValue(static_cast<int>(value));
    query.addBindValue(origin);
    query.exec();
}

void MediaAccessModel::removeExistingEntryFromDatabase(const QString& origin)
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM mediaAccess WHERE origin=?;");
    query.prepare(deleteStatement);
    query.addBindValue(origin);
    query.exec();
}

