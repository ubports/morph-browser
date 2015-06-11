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

#include "history-domainlist-chronological-model.h"
#include "history-domainlist-model.h"

/*!
    \class HistoryDomainListChronologicalModel
    \brief Proxy model that sorts a domain list model in reverse chronological
           order

    HistoryDomainListChronologicalModel is a proxy model that sorts a
    HistoryDomainListModel in reverse chronological order
    (i.e. the domain with the latest entry visited first).
*/
HistoryDomainListChronologicalModel::HistoryDomainListChronologicalModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortRole(HistoryDomainListModel::LastVisit);
    sort(0, Qt::DescendingOrder);
}

HistoryDomainListModel* HistoryDomainListChronologicalModel::sourceModel() const
{
    return qobject_cast<HistoryDomainListModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryDomainListChronologicalModel::setSourceModel(HistoryDomainListModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

QString HistoryDomainListChronologicalModel::get(int index) const
{
    return data(this->index(index, 0), HistoryDomainListModel::Domain).toString();
}
