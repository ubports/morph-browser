/*
 * Copyright 2013-2015 Canonical Ltd.
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
class HistoryModel;

class HistoryDomainListModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(HistoryModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

    Q_ENUMS(Roles)

public:
    HistoryDomainListModel(QObject* parent=0);
    ~HistoryDomainListModel();

    enum Roles {
        Domain = Qt::UserRole + 1,
        LastVisit,
        LastVisitDate,
        LastVisitedTitle,
        LastVisitedIcon,
        Entries
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    HistoryModel* sourceModel() const;
    void setSourceModel(HistoryModel* sourceModel);

    Q_INVOKABLE QVariantMap get(int row) const;

Q_SIGNALS:
    void sourceModelChanged() const;

private Q_SLOTS:
    void onRowsInserted(const QModelIndex& parent, int start, int end);
    void onModelReset();

    void onDomainRowsRemoved(const QModelIndex& parent, int start, int end);
    void onDomainDataChanged();

private:
    HistoryModel* m_sourceModel;
    QMap<QString, HistoryDomainModel*> m_domains;
    QStringList m_domainsPerLastVisit;

    void clearDomains();
    void populateModel();
    void insertNewDomain(const QString& domain);
    QString getDomainFromSourceModel(const QModelIndex& index) const;
    void emitDataChanged(const QString& domain);
};

#endif // __HISTORY_DOMAINLIST_MODEL_H__
