/*
 * Copyright 2019 ubports
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

#include "domain-permissions-model.h"
#include "domain-utils.h"

#include <QtSql/QSqlQuery>
#include <QUrl>

#define CONNECTION_NAME "morph-browser-domainpermissions"

/*!
    \class DomainPermissionsModel
    \brief model that stores domain specific permissions (e.g. block or whitelist domains).
*/
DomainPermissionsModel::DomainPermissionsModel(QObject* parent)
: QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

DomainPermissionsModel::~DomainPermissionsModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void DomainPermissionsModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_entries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
    Q_EMIT rowCountChanged();
}

QHash<int, QByteArray> DomainPermissionsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Domain] = "domain";
        roles[Permission] = "permission";
    }
    return roles;
}

int DomainPermissionsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant DomainPermissionsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const DomainPermissionEntry& entry = m_entries.at(index.row());
    switch (role) {
    case Domain:
        return entry.domain;
    case Permission:
        return entry.permission;
    default:
        return QVariant();
    }
}

void DomainPermissionsModel::createOrAlterDatabaseSchema()
{
    // permissions table
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS domainpermissions "
                                  "(domain VARCHAR NOT NULL UNIQUE, permission INTEGER, PRIMARY KEY(domain));");
    createQuery.prepare(query);
    createQuery.exec();

    // settings table
    QSqlQuery createSettingsQuery(m_database);
    QString settingsQuery = QLatin1String("CREATE TABLE IF NOT EXISTS settings "
                                  "(setting VARCHAR NOT NULL UNIQUE, value VARCHAR NOT NULL);");
    createSettingsQuery.prepare(settingsQuery);
    createSettingsQuery.exec();
}

void DomainPermissionsModel::populateFromDatabase()
{
    // populate domainpermissions
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT domain, permission FROM domainpermissions;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0; // size() isn't supported on the sqlite backend
    while (populateQuery.next()) {
        DomainPermissionEntry entry;
        entry.domain = populateQuery.value("domain").toString();
        entry.permission = static_cast<DomainPermission>(populateQuery.value("permission").toInt());
        beginInsertRows(QModelIndex(), count, count);
        m_entries.append(entry);
        endInsertRows();
        count++;
    }
}

const QString DomainPermissionsModel::databasePath() const
{
    return m_database.databaseName();
}

void DomainPermissionsModel::setDatabasePath(const QString& path)
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

bool DomainPermissionsModel::whiteListMode() const
{
    return m_whiteListMode;
}

void DomainPermissionsModel::setWhiteListMode(bool whiteListMode)
{
    m_whiteListMode = whiteListMode;
    Q_EMIT whiteListModeChanged();
}

DomainPermissionsModel::DomainPermission DomainPermissionsModel::getPermission(const QString& domain) const
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return DomainPermission::NotSet;
    }

    return m_entries[index].permission;
}

void DomainPermissionsModel::setPermission(const QString& domain, DomainPermissionsModel::DomainPermission permission)
{
    insertEntry(domain);
    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainPermissionEntry& entry = m_entries[index];
        if (entry.permission == permission) {
            return;
        }
        entry.permission = permission;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << Permission);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainpermissions SET permission=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue(permission);
        query.addBindValue(domain);
        query.exec();
    }
}

bool DomainPermissionsModel::contains(const QString& domain) const
{
    return (getIndexForDomain(domain) >= 0);
}

void DomainPermissionsModel::insertEntry(const QString &domain)
{
    if (contains(domain))
    {
        return;
    }

    beginInsertRows(QModelIndex(), 0, 0);
    DomainPermissionEntry entry;
    entry.domain = domain;
    entry.permission = DomainPermission::NotSet;
    m_entries.append(entry);
    endInsertRows();
    Q_EMIT rowCountChanged();

    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO domainpermissions (domain, permission) VALUES (?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.domain);
    query.addBindValue(entry.permission);
    query.exec();
}

void DomainPermissionsModel::removeEntry(const QString &domain)
{
    int index = getIndexForDomain(domain);
    if (index != -1) {
        beginRemoveRows(QModelIndex(), index, index);
        m_entries.removeAt(index);
        endRemoveRows();
        Q_EMIT rowCountChanged();
        QSqlQuery query(m_database);
        static QString deleteStatement = QLatin1String("DELETE FROM domainpermissions WHERE domain=?;");
        query.prepare(deleteStatement);
        query.addBindValue(domain);
        query.exec();
    }
}

int DomainPermissionsModel::getIndexForDomain(const QString& domain) const
{
    int index = 0;
    foreach(const DomainPermissionEntry& entry, m_entries) {
        if (entry.domain == domain) {
            return index;
        } else {
            ++index;
        }
    }
    return -1;
}

QString DomainPermissionsModel::getDomainWithoutSubdomain(const QString & domain)
{
    return DomainUtils::getDomainWithoutSubdomain(domain);
}
