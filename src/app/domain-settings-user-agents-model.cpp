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

#include "domain-settings-user-agents-model.h"

#include <QtSql/QSqlQuery>
#include <QUrl>

#define CONNECTION_NAME "morph-browser-domainsettings-user-agents"

/*!
    \class UserAgentsModel
    \brief model that stores custom user agents.
*/
UserAgentsModel::UserAgentsModel(QObject* parent)
: QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

UserAgentsModel::~UserAgentsModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void UserAgentsModel::resetDatabase(const QString& databaseName)
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

QHash<int, QByteArray> UserAgentsModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Id] = "id";
        roles[Name] = "name";
        roles[UserAgentString] = "userAgentString";
    }
    return roles;
}

int UserAgentsModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant UserAgentsModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const UserAgent& entry = m_entries.at(index.row());
    switch (role) {
    case Id:
        return entry.id;
    case Name:
        return entry.name;
    default:
        return QVariant();
    }
}

void UserAgentsModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS useragents "
                                  "(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE, name VARCHAR, userAgentString VARCHAR);");
    createQuery.prepare(query);
    createQuery.exec();
}

void UserAgentsModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT id, name, userAgentString FROM useragents");
    populateQuery.prepare(query);
    populateQuery.exec();
    int count = 0; // size() isn't supported on the sqlite backend
    while (populateQuery.next()) {
        UserAgent entry;
        entry.id = populateQuery.value("id").toInt();
        entry.name = populateQuery.value("name").toString();
        entry.userAgentString = populateQuery.value("userAgentString").toString();
        beginInsertRows(QModelIndex(), count, count);
        m_entries.append(entry);
        endInsertRows();
        count++;
    }
}

const QString UserAgentsModel::databasePath() const
{
    return m_database.databaseName();
}

void UserAgentsModel::setDatabasePath(const QString& path)
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

bool UserAgentsModel::contains(const QString& userAgentName) const
{
    return (getIndexForUserAgentName(userAgentName) >= 0);
}

void UserAgentsModel::insertEntry(const QString& userAgentName, const QString& userAgentString)
{
    if (contains(userAgentName))
    {
        return;
    }

    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO useragents (name, userAgentString) VALUES (?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(userAgentName);
    query.addBindValue(userAgentString);
    query.exec();

    beginInsertRows(QModelIndex(), 0, 0);
    UserAgent entry;
    entry.id = query.lastInsertId().toInt();
    entry.name = userAgentName;
    entry.userAgentString = userAgentString;
    m_entries.append(entry);
    endInsertRows();
    Q_EMIT rowCountChanged();
}

void UserAgentsModel::removeEntry(int userAgentId)
{
    int index = getIndexForUserAgentId(userAgentId);
    if (index != -1) {
        beginRemoveRows(QModelIndex(), index, index);
        m_entries.removeAt(index);
        endRemoveRows();
        Q_EMIT rowCountChanged();
        QSqlQuery query(m_database);
        static QString deleteStatement = QLatin1String("DELETE FROM useragents WHERE id=?;");
        query.prepare(deleteStatement);
        query.addBindValue(userAgentId);
        query.exec();
    }
}

void UserAgentsModel::setUserAgentString(int userAgentId, const QString& userAgentString)
{
    int index = getIndexForUserAgentId(userAgentId);
    if (index != -1) {
        UserAgent& entry = m_entries[index];
        if (entry.userAgentString == userAgentString) {
            return;
        }
        entry.userAgentString = userAgentString;
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), QVector<int>() << UserAgentString);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE useragents SET userAgentString=? WHERE id=?;");
        query.prepare(updateStatement);
        query.addBindValue(userAgentString);
        query.addBindValue(userAgentId);
        query.exec();
    }
}

int UserAgentsModel::getIndexForUserAgentId(int userAgentId) const
{
    int index = 0;
    Q_FOREACH(const UserAgent& entry, m_entries) {
        if (entry.id == userAgentId) {
            return index;
        } else {
            ++index;
        }
    }
    return -1;
}

int UserAgentsModel::getUserAgentIdForIndex(int index) const
{
    return m_entries[index].id;
}

int UserAgentsModel::getIndexForUserAgentName(const QString& userAgentName) const
{
    int index = 0;
    Q_FOREACH(const UserAgent& entry, m_entries) {
        if (entry.name == userAgentName) {
            return index;
        } else {
            ++index;
        }
    }
    return -1;
}
