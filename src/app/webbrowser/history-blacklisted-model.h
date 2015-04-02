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

#ifndef __HISTORY_BLACKLISTED_MODEL_H__
#define __HISTORY_BLACKLISTED_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>
#include <QtSql/QSqlDatabase>

class HistoryTimeframeModel;

class HistoryBlacklistedModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryTimeframeModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)

public:
    HistoryBlacklistedModel(QObject* parent=0);
    ~HistoryBlacklistedModel();

    HistoryTimeframeModel* sourceModel() const;
    void setSourceModel(HistoryTimeframeModel* sourceModel);

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE void addToBlacklist(const QUrl& blacklistedUrl);

Q_SIGNALS:
    void sourceModelChanged() const;
    void databasePathChanged() const;

private:
    QSqlDatabase m_database;
    QList<QUrl> m_blacklistedEntries;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void insertNewEntryInDatabase(const QUrl& url);

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;
};

#endif // __HISTORY_BLACKLISTED_MODEL_H__
