/*
 * Copyright 2013 Canonical Ltd.
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

#include "history-model.h"

// Qt
#include <QtSql/QSqlQuery>

HistoryModel::HistoryModel(const QString& databasePath, QObject* parent)
    : QAbstractListModel(parent)
{
    QString connectionName = "webbrowser-app-history";
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), connectionName);
    m_database.setDatabaseName(databasePath);
    m_database.open();

    // create the table if it doesn’t exist yet
    QSqlQuery schemaQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS history "
                                  "(url VARCHAR, title VARCHAR, icon VARCHAR,"
                                  " visits INTEGER, lastVisit DATETIME);");
    schemaQuery.prepare(query);
    schemaQuery.exec();

    // initial population of the model
    QSqlQuery countQuery(m_database);
    query = QLatin1String("SELECT COUNT(*) FROM history;");
    countQuery.prepare(query);
    countQuery.exec();
    int count = countQuery.first() ? countQuery.value(0).toInt() : 0;
    if (count > 0) {
        beginInsertRows(QModelIndex(), 0, count - 1);
        QSqlQuery populateQuery(m_database);
        query = QLatin1String("SELECT url, title, icon, visits, lastVisit "
                              "FROM history ORDER BY lastVisit DESC;");
        populateQuery.prepare(query);
        populateQuery.exec();
        while (populateQuery.next()) {
            HistoryEntry entry;
            entry.url = populateQuery.value(0).toUrl();
            entry.title = populateQuery.value(1).toString();
            entry.icon = populateQuery.value(2).toUrl();
            entry.visits = populateQuery.value(3).toInt();
            entry.lastVisit = QDateTime::fromTime_t(populateQuery.value(4).toInt());
            m_entries.append(entry);
        }
        endInsertRows();
    }
}

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Url] = "url";
        roles[Title] = "title";
        roles[Icon] = "icon";
        roles[Visits] = "visits";
        roles[LastVisit] = "lastVisit";
    }
    return roles;
}

int HistoryModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant HistoryModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    int row = index.row();
    if ((row < 0) || (row >= m_entries.count())) {
        return QVariant();
    }
    const HistoryEntry& entry = m_entries.at(row);
    switch (role) {
    case Url:
        return entry.url;
    case Title:
        return entry.title;
    case Icon:
        return entry.icon;
    case Visits:
        return entry.visits;
    case LastVisit:
        return entry.lastVisit;
    default:
        return QVariant();
    }
}

int HistoryModel::getEntryIndex(const QUrl& url) const
{
    for (int i = 0; i < m_entries.count(); ++i) {
        if (m_entries.at(i).url == url) {
            return i;
        }
    }
    return -1;
}

int HistoryModel::add(const QUrl& url, const QString& title, const QUrl& icon)
{
    if (url.isEmpty()) {
        return 0;
    }
    int count = 1;
    QDateTime now = QDateTime::currentDateTimeUtc();
    int index = getEntryIndex(url);
    if (index == -1) {
        HistoryEntry entry;
        entry.url = url;
        entry.title = title;
        entry.icon = icon;
        entry.visits = 1;
        entry.lastVisit = now;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        QSqlQuery query(m_database);
        static QString insertStatement = QLatin1String("INSERT INTO history (url, title, icon, "
                                                       "visits, lastVisit) VALUES (?, ?, ?, 1, ?);");
        query.prepare(insertStatement);
        query.addBindValue(url.toString());
        query.addBindValue(title);
        query.addBindValue(icon.toString());
        query.addBindValue(now.toTime_t());
        query.exec();
    } else {
        QVector<int> roles;
        roles << Visits;
        if (index == 0) {
            HistoryEntry& entry = m_entries.first();
            if (title != entry.title) {
                entry.title = title;
                roles << Title;
            }
            if (icon != entry.icon) {
                entry.icon = icon;
                roles << Icon;
            }
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                entry.lastVisit = now;
                roles << LastVisit;
            }
        } else {
            beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
            HistoryEntry entry = m_entries.takeAt(index);
            if (title != entry.title) {
                entry.title = title;
                roles << Title;
            }
            if (icon != entry.icon) {
                entry.icon = icon;
                roles << Icon;
            }
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                entry.lastVisit = now;
                roles << LastVisit;
            }
            m_entries.prepend(entry);
            endMoveRows();
        }
        Q_EMIT dataChanged(this->index(0, 0), this->index(0, 0), roles);
        QSqlQuery query(m_database);
        static QString updateStatement = QLatin1String("UPDATE history SET title=?, icon=?, "
                                                       "visits=?, lastVisit=? WHERE url=?;");
        query.prepare(updateStatement);
        query.addBindValue(title);
        query.addBindValue(icon.toString());
        query.addBindValue(count);
        query.addBindValue(now.toTime_t());
        query.addBindValue(url.toString());
        query.exec();
    }
    return count;
}
