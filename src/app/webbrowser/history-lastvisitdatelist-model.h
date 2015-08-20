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

#ifndef __HISTORY_LASTVISITDATELIST_MODEL_H__
#define __HISTORY_LASTVISITDATELIST_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QMap>
#include <QtCore/QString>
#include <QtCore/QSortFilterProxyModel>

class HistoryLastVisitDateListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QVariant sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

    Q_ENUMS(Roles)

public:
    HistoryLastVisitDateListModel(QObject* parent=0);
    ~HistoryLastVisitDateListModel();

    enum Roles {
        LastVisitDate = Qt::UserRole + 1
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    QVariant sourceModel() const;
    void setSourceModel(QVariant sourceModel);

Q_SIGNALS:
    void sourceModelChanged() const;

private Q_SLOTS:
    void onRowsInserted(const QModelIndex& parent, int start, int end);
    void onRowsRemoved(const QModelIndex& parent, int start, int end);
    void onModelReset();

private:
    QAbstractItemModel* m_sourceModel;
    int m_sourceModelRole;
    QMap<QDate, QList<QPersistentModelIndex*>*> m_lastVisitDates;
    QList<QDate> m_orderedDates;

    void clearLastVisitDates();
    void populateModel();
    void insertNewHistoryEntry(QPersistentModelIndex* index, bool notify);
    void updateSourceModelRole();
};

#endif // __HISTORY_LASTVISITDATELIST_MODEL_H__
