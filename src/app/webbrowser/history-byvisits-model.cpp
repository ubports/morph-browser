/*
 * Copyright 2014 Canonical Ltd.
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

#include "history-byvisits-model.h"
#include "history-blacklisted-model.h"
#include "history-model.h"

/*!
    \class HistoryByVisitsModel
    \brief Proxy model that sorts a history model by number of visits

    HistoryByVisitsModel is a proxy model that sorts a
    HistoryTimeframeModel by the number of visits
    (i.e. the history with the greatest number of visits first).
*/
HistoryByVisitsModel::HistoryByVisitsModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortRole(HistoryModel::Visits);
    sort(0, Qt::DescendingOrder);
}

HistoryBlacklistedModel* HistoryByVisitsModel::sourceModel() const
{
    return qobject_cast<HistoryBlacklistedModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryByVisitsModel::setSourceModel(HistoryBlacklistedModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}
