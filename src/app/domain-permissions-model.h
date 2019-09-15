/*
 * Copyright 2019 Chris Clime
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __DOMAIN_PERMISSIONS_MODEL_H__
#define __DOMAIN_PERMISSIONS_MODEL_H__

#include <QAbstractListModel>
#include <QtCore/QDateTime>
#include <QString>
#include <QtSql/QSqlDatabase>

class DomainPermissionsModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)
    Q_PROPERTY(bool whiteListMode READ whiteListMode WRITE setWhiteListMode NOTIFY whiteListModeChanged)

    Q_ENUMS(Roles)

public:
    DomainPermissionsModel(QObject* parent=0);
    ~DomainPermissionsModel();

    enum DomainPermission {
        NotSet = 0,
        Blocked = 1,
        Whitelisted = 2
    };
    Q_ENUMS(DomainPermission)

    enum Roles {
        Domain = Qt::UserRole + 1,
        Permission,
        RequestedByDomain,
        LastRequested
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    bool whiteListMode() const;
    void setWhiteListMode(bool whiteListMode);
    
    Q_INVOKABLE bool contains(const QString& domain) const;
    Q_INVOKABLE void deleteAndResetDataBase();
    Q_INVOKABLE DomainPermission getPermission(const QString& domain) const;
    Q_INVOKABLE void setPermission(const QString& domain, DomainPermission permission, bool incognito);
    Q_INVOKABLE void setRequestedByDomain(const QString& domain, const QString& requestedByDomain, bool incognito);
    Q_INVOKABLE void insertEntry(const QString& domain, bool incognito);
    Q_INVOKABLE void removeEntry(const QString& domain);
    Q_INVOKABLE static QString getDomainWithoutSubdomain(const QString & domain);

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();
    void whiteListModeChanged();

private:
    QSqlDatabase m_database;
    bool m_whiteListMode;

    struct DomainPermissionEntry {
        QString domain;
        QString requestedByDomain;
        DomainPermission permission;
        QDateTime lastRequested;
    };

    QList<DomainPermissionEntry> m_entries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    int getIndexForDomain(const QString& domain) const;
};

#endif
