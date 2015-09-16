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

#ifndef __MEDIA_ACCESS_MODEL_H__
#define __MEDIA_ACCESS_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QList>
#include <QtCore/QSet>
#include <QtCore/QString>
#include <QtCore/QUrl>
#include <QtSql/QSqlDatabase>

typedef QPair<QVariant, QVariant> QVariantPair;

class MediaAccessModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    MediaAccessModel(QObject* parent=0);
    ~MediaAccessModel();

    enum Roles {
        Origin = Qt::UserRole + 1,
        Audio,
        Video,
        Filter,
        ValuesSet
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE QVariant get(const QUrl& origin) const;
    Q_INVOKABLE void set(const QUrl& origin, const QVariant& audio, const QVariant& video);
    Q_INVOKABLE void unset(const QUrl& origin, bool unsetAudio, bool unsetVideo);

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();

private:
    QSqlDatabase m_database;

    enum PermissionValue {
        Unset = 0,
        Allow = 1,
        Deny = 2
    };

    enum PermissionType {
        AudioPermission,
        VideoPermission
    };

    struct Permissions {
        PermissionValue audio;
        PermissionValue video;
    };

    QHash<QUrl, Permissions> m_data;
    QList<QUrl> m_ordered;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void insertNewEntryInDatabase(const QUrl& origin, const Permissions& permissions);
    void removeExistingEntryFromDatabase(const QUrl& origin);
    void updateExistingEntryInDatabase(const QUrl& origin, PermissionType which, PermissionValue value);
};

#endif // __MEDIA_ACCESS_MODEL_H__
