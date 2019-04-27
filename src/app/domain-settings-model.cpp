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

#include "domain-settings-model.h"

#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "morph-browser-domainsettings"

/*!
    \class DomainSettingsModel
    \brief model that stores domain specific settings.
*/
DomainSettingsModel::DomainSettingsModel()
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

DomainSettingsModel::~DomainSettingsModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void DomainSettingsModel::resetDatabase(const QString& databaseName)
{
    //beginResetModel();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    m_numRows = 0;
    createOrAlterDatabaseSchema();
    //endResetModel();
    //Q_EMIT rowCountChanged();
}

void DomainSettingsModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS domainsettings "
                                  "(domain VARCHAR, allowCustomUrlSchemes BOOL, allowLocation BOOL, "
                                  "userAgent VARCHAR, zoomFactor REAL); ");
    createQuery.prepare(query);
    createQuery.exec();
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

bool DomainSettingsModel::contains(const QString& domain) const
{
    QSqlQuery query(m_database);
    static QString selectStatement = QLatin1String("SELECT COUNT(domain) FROM domainsettings WHERE domain=?;");
    query.prepare(selectStatement);
    query.addBindValue(domain);
    query.exec();
    query.first();
    return (query.value(0).toInt() > 0);
}

void DomainSettingsModel::allowCustomUrlSchemes(const QString& domain, bool allow)
{
    insertEntry(domain);

    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE domainsettings SET allowCustomUrlSchemes=? WHERE domain=?;");
    query.prepare(updateStatement);
    query.addBindValue(allow);
    query.addBindValue(domain);
    query.exec();
}

bool DomainSettingsModel::areCustomUrlSchemesAllowed(const QString& domain)
{
    QSqlQuery query(m_database);
    static QString selectStatement = QLatin1String("SELECT allowCustomUrlSchemes FROM domainsettings WHERE domain=?;");
    query.prepare(selectStatement);
    query.addBindValue(domain);
    query.exec();
    query.first();
    return query.value(0).toBool();
}

void DomainSettingsModel::allowLocation(const QString& domain, bool allow)
{
    insertEntry(domain);

    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE domainsettings SET allowCustomUrlSchemes=? WHERE domain=?;");
    query.prepare(updateStatement);
    query.addBindValue(allow);
    query.addBindValue(domain);
    query.exec();
}
void DomainSettingsModel::setUserAgent(const QString& domain, QString userAgent)
{
    insertEntry(domain);

    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE domainsettings SET userAgent=? WHERE domain=?;");
    query.prepare(updateStatement);
    query.addBindValue(userAgent);
    query.addBindValue(domain);
    query.exec();
}
void DomainSettingsModel::setZoomFactor(const QString& domain, double zoomFactor)
{
    insertEntry(domain);

    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE domainsettings SET zoomFactor=? WHERE domain=?;");
    query.prepare(updateStatement);
    query.addBindValue(zoomFactor);
    query.addBindValue(domain);
    query.exec();
}

void DomainSettingsModel::insertEntry(const QString &domain)
{
    if (contains(domain))
    {
        return;
    }

    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO domainsettings (domain, allowCustomUrlSchemes, allowLocation, userAgent, zoomFactor)"
                                                   " VALUES (?, ?, ?, ?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(domain);
    query.addBindValue(false);
    query.addBindValue(false);
    query.addBindValue("");
    query.addBindValue(1.0);
    query.exec();
}

void DomainSettingsModel::removeEntry(const QString &domain)
{
    QSqlQuery query(m_database);
    static QString deleteStatement = QLatin1String("DELETE FROM domainsettings WHERE domain=?;");
    query.prepare(deleteStatement);
    query.addBindValue(domain);
    query.exec();
}
