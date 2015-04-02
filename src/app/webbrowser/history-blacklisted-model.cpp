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

bool HistoryBlacklistedModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
//    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
//    QDateTime lastVisit = sourceModel()->data(index, HistoryModel::LastVisit).toDateTime();
//    if (m_start.isValid() && (lastVisit < m_start)) {
//        return false;
//    }
//    if (m_end.isValid() && (lastVisit > m_end)) {
//        return false;
//    }
    return false;
}
