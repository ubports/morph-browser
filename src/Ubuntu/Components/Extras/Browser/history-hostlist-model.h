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

#ifndef __HISTORY_HOSTLIST_MODEL_H__
#define __HISTORY_HOSTLIST_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QMap>
#include <QtCore/QString>

class HistoryHostModel;
class HistoryTimeframeModel;

class HistoryHostListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryTimeframeModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

    Q_ENUMS(Roles)

public:
    HistoryHostListModel(QObject* parent=0);
    ~HistoryHostListModel();

    enum Roles {
        Host = Qt::UserRole + 1,
        Entries
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    HistoryTimeframeModel* sourceModel() const;
    void setSourceModel(HistoryTimeframeModel* sourceModel);

Q_SIGNALS:
    void sourceModelChanged() const;

private Q_SLOTS:
    void onRowsInserted(const QModelIndex& parent, int start, int end);
    void onRowsRemoved(const QModelIndex& parent, int start, int end);
    void onModelReset();

private:
    HistoryTimeframeModel* m_sourceModel;
    QMap<QString, HistoryHostModel*> m_hosts;

    void clearHosts();
    void populateModel();
    void insertNewHost(const QString& host);
    QString getHostFromSourceModel(const QModelIndex& index) const;
};

#endif // __HISTORY_HOSTLIST_MODEL_H__
