/*
 * Copyright 2020 UBports Foundation
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

#include "domain-settings-model.h"
#include "domain-utils.h"

#include <QFile>
#include <QtSql/QSqlQuery>
#include <QUrl>
#include <cmath>

#define CONNECTION_NAME "morph-browser-domainsettings"

namespace
{
  const double ZoomFactorCompareThreshold = 0.01;
}

/*!
    \class DomainSettingsModel
    \brief model that stores domain specific settings.
*/
DomainSettingsModel::DomainSettingsModel(QObject* parent)
: QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
    m_defaultZoomFactor = 1.0;
}

DomainSettingsModel::~DomainSettingsModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void DomainSettingsModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_entries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    removeObsoleteEntries();
    endResetModel();
    populateFromDatabase();
    Q_EMIT rowCountChanged();
}

QHash<int, QByteArray> DomainSettingsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Domain] = "domain";
        roles[DomainWithoutSubdomain] = "domainWithoutSubdomain";
        roles[AllowCustomUrlSchemes] = "allowCustomUrlSchemes";
        roles[AllowLocation] = "allowLocation";
        roles[AllowNotifications] = "allowNotifications";
        roles[UserAgentId] = "userAgentId";
        roles[ZoomFactor] = "zoomFactor";
    }
    return roles;
}

int DomainSettingsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant DomainSettingsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const DomainSetting& entry = m_entries.at(index.row());
    switch (role) {
    case Domain:
        return entry.domain;
    case DomainWithoutSubdomain:
        return entry.domainWithoutSubdomain;
    case AllowCustomUrlSchemes:
        return entry.allowCustomUrlSchemes;
    case AllowLocation:
        return entry.allowLocation;
    case AllowNotifications:
        return entry.allowNotifications;
    case UserAgentId:
        return entry.userAgentId;
    case ZoomFactor:
        return entry.zoomFactor;
    default:
        return QVariant();
    }
}

void DomainSettingsModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS domainsettings "
                                  "(domain VARCHAR NOT NULL UNIQUE, domainWithoutSubdomain VARCHAR, allowCustomUrlSchemes BOOL, allowLocation INTEGER, allowNotifications INTEGER, "
                                  "userAgentId INTEGER, zoomFactor REAL, PRIMARY KEY(domain), FOREIGN KEY(userAgentId) REFERENCES useragents(id)); ");
    createQuery.prepare(query);
    createQuery.exec();

    // Older version of the database schema didn’t have the column 'allowNotifications'
    QSqlQuery tableInfoQuery(m_database);
    query = QLatin1String("PRAGMA TABLE_INFO(domainsettings);");
    tableInfoQuery.prepare(query);
    tableInfoQuery.exec();

    bool missingAllowNotificationsColumn = true;

    while (tableInfoQuery.next()) {
        if (tableInfoQuery.value("name").toString() == "allowNotifications") {
            missingAllowNotificationsColumn = false;
        }
        if (!missingAllowNotificationsColumn) {
            break;
        }
    }

    if (missingAllowNotificationsColumn) {
        QSqlQuery addFolderColumnQuery(m_database);
        query = QLatin1String("ALTER TABLE domainsettings ADD COLUMN allowNotifications INTEGER;");
        addFolderColumnQuery.prepare(query);
        addFolderColumnQuery.exec();
    }
}

void DomainSettingsModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT domain, domainWithoutSubdomain, allowCustomUrlSchemes, allowLocation, allowNotifications, userAgentId, zoomFactor "
                                  "FROM domainsettings;");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0; // size() isn't supported on the sqlite backend
    while (populateQuery.next()) {
        DomainSetting entry;
        entry.domain = populateQuery.value("domain").toString();
        entry.domainWithoutSubdomain = populateQuery.value("domainWithoutSubdomain").toString();
        entry.allowCustomUrlSchemes = populateQuery.value("allowCustomUrlSchemes").toBool();
        entry.allowLocation = static_cast<AllowLocationPreference>(populateQuery.value("allowLocation").toInt());
        entry.allowNotifications = static_cast<NotificationsPreference>(populateQuery.value("allowNotifications").toInt());
        entry.userAgentId = populateQuery.value("userAgentId").toInt();
        entry.zoomFactor =  populateQuery.value("zoomFactor").isNull() ? std::numeric_limits<double>::quiet_NaN()
                                                                       : populateQuery.value("zoomFactor").toDouble();

        beginInsertRows(QModelIndex(), count, count);
        m_entries.append(entry);
        endInsertRows();
        count++;
    }
}

const QString DomainSettingsModel::databasePath() const
{
    return m_database.databaseName();
}

void DomainSettingsModel::setDatabasePath(const QString& path)
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

double DomainSettingsModel::defaultZoomFactor() const
{
    return m_defaultZoomFactor;
}

void DomainSettingsModel::setDefaultZoomFactor(double defaultZoomFactor)
{
    m_defaultZoomFactor = defaultZoomFactor;
}

bool DomainSettingsModel::contains(const QString& domain) const
{
    return (getIndexForDomain(domain) >= 0);
}

void DomainSettingsModel::deleteAndResetDataBase()
{
    if (QFile::exists(databasePath()))
    {
        QFile(databasePath()).remove();
    }
    resetDatabase(databasePath());
}

bool DomainSettingsModel::areCustomUrlSchemesAllowed(const QString& domain)
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return false;
    }

    return m_entries[index].allowCustomUrlSchemes;
}

void DomainSettingsModel::allowCustomUrlSchemes(const QString& domain, bool allow)
{
    insertEntry(domain);

    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        if (entry.allowCustomUrlSchemes == allow) {
            return;
        }
        entry.allowCustomUrlSchemes = allow;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << AllowCustomUrlSchemes);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET allowCustomUrlSchemes=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue(allow);
        query.addBindValue(domain);
        query.exec();
    }
}

DomainSettingsModel::AllowLocationPreference DomainSettingsModel::getLocationPreference(const QString& domain) const
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return AllowLocationPreference::AskForLocationAccess;
    }

    return m_entries[index].allowLocation;
}

void DomainSettingsModel::setLocationPreference(const QString& domain, DomainSettingsModel::AllowLocationPreference preference)
{
    insertEntry(domain);

    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        if (entry.allowLocation == preference) {
            return;
        }
        entry.allowLocation = preference;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << AllowLocation);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET allowLocation=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue(entry.allowLocation);
        query.addBindValue(domain);
        query.exec();
    }
}

DomainSettingsModel::NotificationsPreference DomainSettingsModel::getNotificationsPreference(const QString& domain) const
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return NotificationsPreference::AskForNotificationsAccess;
    }

    return m_entries[index].allowNotifications;
}

void DomainSettingsModel::setNotificationsPreference(const QString& domain, DomainSettingsModel::NotificationsPreference preference)
{
    insertEntry(domain);

    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        if (entry.allowNotifications == preference) {
            return;
        }
        entry.allowNotifications = preference;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << AllowNotifications);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET allowNotifications=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue(entry.allowNotifications);
        query.addBindValue(domain);
        query.exec();
    }
}

int DomainSettingsModel::getUserAgentId(const QString& domain) const
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return std::numeric_limits<int>::quiet_NaN();
    }

    return m_entries[index].userAgentId;
}

void DomainSettingsModel::setUserAgentId(const QString& domain, int userAgentId)
{
    insertEntry(domain);

    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        if (entry.userAgentId == userAgentId) {
            return;
        }
        entry.userAgentId = userAgentId;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << UserAgentId);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET userAgentId=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue((userAgentId > 0) ? userAgentId : QVariant());
        query.addBindValue(domain);
        query.exec();
    }
}

void DomainSettingsModel::removeUserAgentIdFromAllDomains(int userAgentId)
{
    bool foundDomainWithGivenUserAgentId = false;
    for (int i = 0; i < m_entries.length(); i++)
    {
        if (m_entries[i].userAgentId == userAgentId) {
            foundDomainWithGivenUserAgentId = true;
            m_entries[i].userAgentId = 0;
            Q_EMIT dataChanged(this->index(i, 0), this->index(i, 0), QVector<int>() << UserAgentId);
        }
    }

    if (foundDomainWithGivenUserAgentId)
    {
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET userAgentId=NULL WHERE userAgentId=?;");
        query.prepare(updateStatement);
        query.addBindValue(userAgentId);
        query.exec();
    }
}

double DomainSettingsModel::getZoomFactor(const QString& domain) const
{
    int index = getIndexForDomain(domain);
    if (index == -1)
    {
        return std::numeric_limits<double>::quiet_NaN();
    }

    return m_entries[index].zoomFactor;
}

void DomainSettingsModel::setZoomFactor(const QString& domain, double zoomFactor)
{
    insertEntry(domain);

    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        if (std::abs(entry.zoomFactor - zoomFactor) < ZoomFactorCompareThreshold) {
            return;
        }
        entry.zoomFactor = zoomFactor;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << ZoomFactor);
        Q_EMIT domainZoomFactorChanged(domain);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE domainsettings SET zoomFactor=? WHERE domain=?;");
        query.prepare(updateStatement);
        query.addBindValue(zoomFactor);
        query.addBindValue(domain);
        query.exec();
    }
}

void DomainSettingsModel::insertEntry(const QString &domain)
{
    if (contains(domain))
    {
        return;
    }

    beginInsertRows(QModelIndex(), 0, 0);
    DomainSetting entry;
    entry.domain = domain;
    entry.domainWithoutSubdomain = DomainUtils::getDomainWithoutSubdomain(domain);
    entry.allowCustomUrlSchemes = false;
    entry.allowLocation = AllowLocationPreference::AskForLocationAccess;
    entry.allowNotifications = NotificationsPreference::AskForNotificationsAccess;
    entry.userAgentId = 0;
    entry.zoomFactor = std::numeric_limits<double>::quiet_NaN();
    m_entries.append(entry);
    endInsertRows();
    Q_EMIT rowCountChanged();

    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO domainsettings (domain, domainWithoutSubdomain, allowCustomUrlSchemes, allowLocation, allowNotifications, userAgentId, zoomFactor)"
                                                   " VALUES (?, ?, ?, ?, ?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.domain);
    query.addBindValue(entry.domainWithoutSubdomain);
    query.addBindValue(entry.allowCustomUrlSchemes);
    query.addBindValue(entry.allowLocation);
    query.addBindValue(entry.allowNotifications);
    query.addBindValue((entry.userAgentId > 0) ? entry.userAgentId : QVariant());
    query.addBindValue(entry.zoomFactor);
    query.exec();
}

void DomainSettingsModel::removeEntry(const QString &domain)
{
    int index = getIndexForDomain(domain);
    if (index != -1) {
        DomainSetting& entry = m_entries[index];
        beginRemoveRows(QModelIndex(), index, index);
        m_entries.removeAt(index);
        endRemoveRows();
        Q_EMIT rowCountChanged();
        if (!std::isnan(entry.zoomFactor))
        {
            Q_EMIT domainZoomFactorChanged(domain);
        }
        QSqlQuery query(m_database);
        static QString deleteStatement = QLatin1String("DELETE FROM domainsettings WHERE domain=?;");
        query.prepare(deleteStatement);
        query.addBindValue(domain);
        query.exec();
    }
}

void DomainSettingsModel::removeObsoleteEntries()
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM domainsettings WHERE allowCustomUrlSchemes=? AND allowLocation=? AND allowNotifications=? AND userAgentId IS NULL AND zoomFactor IS NULL;");
    query.prepare(deleteStatement);
    query.addBindValue(false);
    query.addBindValue(AllowLocationPreference::AskForLocationAccess);
    query.addBindValue(NotificationsPreference::AskForNotificationsAccess);
    query.exec();
}

int DomainSettingsModel::getIndexForDomain(const QString& domain) const
{
    int index = 0;
    foreach(const DomainSetting& entry, m_entries) {
        if (entry.domain == domain) {
            return index;
        } else {
            ++index;
        }
    }
    return -1;
}
