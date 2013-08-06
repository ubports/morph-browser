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

#ifndef __HISTORY_DOMAINLIST_MODEL_H__
#define __HISTORY_DOMAINLIST_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QMap>
#include <QtCore/QString>

class HistoryDomainModel;
class HistoryTimeframeModel;

class HistoryDomainListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryTimeframeModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

    Q_ENUMS(Roles)

public:
    HistoryDomainListModel(QObject* parent=0);
    ~HistoryDomainListModel();

    enum Roles {
        Domain = Qt::UserRole + 1,
        LastVisit,
        Thumbnail,
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
    void onModelReset();

    void onDomainRowsInserted(const QModelIndex& parent, int start, int end);
    void onDomainRowsRemoved(const QModelIndex& parent, int start, int end);
    void onDomainRowsMoved(const QModelIndex& sourceParent, int sourceStart, int sourceEnd, const QModelIndex& destinationParent, int destinationRow);
    void onDomainLayoutChanged(const QList<QPersistentModelIndex>& parents, QAbstractItemModel::LayoutChangeHint hint);
    void onDomainDataChanged(const QModelIndex& topLeft, const QModelIndex& bottomRight);
    void onDomainModelReset();

private:
    HistoryTimeframeModel* m_sourceModel;
    QMap<QString, HistoryDomainModel*> m_domains;

    void clearDomains();
    void populateModel();
    void insertNewDomain(const QString& domain);
    QString getDomainFromSourceModel(const QModelIndex& index) const;
    void emitDataChanged(const QString& domain);
};

#endif // __HISTORY_DOMAINLIST_MODEL_H__
