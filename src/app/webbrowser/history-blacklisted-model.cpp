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

#include "history-blacklisted-model.h"
#include "history-timeframe-model.h"
#include "history-model.h"

// Qt
#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "webbrowser-app-history-blacklist"

/*!
    \class HistoryBlacklistedModel
    \brief Proxy model that filters a history model based on a blacklist

    HistoryBlacklistedModel is a proxy model that filters a
    HistoryTimeframeModel based on a blacklist stored on database
    (i.e. ignores history that was marked as removed by user).
*/
HistoryBlacklistedModel::HistoryBlacklistedModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

HistoryBlacklistedModel::~HistoryBlacklistedModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void HistoryBlacklistedModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_blacklistedEntries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    populateFromDatabase();
    endResetModel();
}

void HistoryBlacklistedModel::createOrAlterDatabaseSchema()
{
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS history_blacklist "
                                  "(url VARCHAR, blacklisted DATETIME);");
    createQuery.prepare(query);
    createQuery.exec();
}

void HistoryBlacklistedModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT url FROM history_blacklist;");
    populateQuery.prepare(query);
    populateQuery.exec();
    while (populateQuery.next()) {
        m_blacklistedEntries.append(populateQuery.value(0).toUrl());
    }
}

HistoryTimeframeModel* HistoryBlacklistedModel::sourceModel() const
{
    return qobject_cast<HistoryTimeframeModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryBlacklistedModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QString HistoryBlacklistedModel::databasePath() const
{
    return m_database.databaseName();
}

void HistoryBlacklistedModel::setDatabasePath(const QString& path)
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

void HistoryBlacklistedModel::insertNewEntryInDatabase(const QUrl& url)
{
    QDateTime now = QDateTime::currentDateTimeUtc();
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO history_blacklist (url, blacklisted) VALUES (?, ?);");
    query.prepare(insertStatement);
    query.addBindValue(url.toString());
    query.addBindValue(now.toTime_t());
    query.exec();
}

void HistoryBlacklistedModel::add(const QUrl& blacklistedUrl)
{
    if (blacklistedUrl.isEmpty() || m_blacklistedEntries.contains(blacklistedUrl)) {
        return;
    }

    m_blacklistedEntries.append(blacklistedUrl);
    insertNewEntryInDatabase(blacklistedUrl);

    int count = rowCount();
    QList<QPersistentModelIndex> affectedIndexes;

    for (int i = 0; i < count; ++i) {
        QModelIndex idx = index(i, 0);
        QUrl url = data(idx, HistoryModel::Url).toUrl();
        if (url == blacklistedUrl) {
            affectedIndexes << idx;
        }
    }

    Q_FOREACH(const QPersistentModelIndex &idx, affectedIndexes) {
        QModelIndex sourceIndex = mapToSource(idx);
        Q_EMIT sourceModel()->dataChanged(sourceIndex, sourceIndex);
    } 
}

bool HistoryBlacklistedModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QUrl url = sourceModel()->data(index, HistoryModel::Url).toUrl();
    return !m_blacklistedEntries.contains(url);
}
