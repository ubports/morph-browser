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

#include "history-lastvisitdate-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QUrl>

/*!
    \class HistoryLastVisitDateModel
    \brief Proxy model that filters the contents of a history model
           based on last visit date

    HistoryLastVisitDateModel is a proxy model that filters the contents
    of a history model based on the last visit date.

    An entry in the history model matches if the last visit date equals
    the filter visit date.

    When no visit date is set, all entries match.
*/
HistoryLastVisitDateModel::HistoryLastVisitDateModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryTimeframeModel* HistoryLastVisitDateModel::sourceModel() const
{
    return qobject_cast<HistoryTimeframeModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryLastVisitDateModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QDate& HistoryLastVisitDateModel::lastVisitDate() const
{
    return m_lastVisitDate;
}

void HistoryLastVisitDateModel::setLastVisitDate(const QDate& lastVisitDate)
{
    if (lastVisitDate != m_lastVisitDate) {
        m_lastVisitDate = lastVisitDate;
        invalidate();
        Q_EMIT lastVisitDateChanged();
    }
}

bool HistoryLastVisitDateModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_lastVisitDate.isNull()) {
        return true;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    return m_lastVisitDate == sourceModel()->data(index, HistoryModel::LastVisitDate).toDate();
}
