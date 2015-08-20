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

#include "history-timeframe-model.h"
#include "history-model.h"

/*!
    \class HistoryTimeframeModel
    \brief Proxy model that filters the contents of the history model
           excluding all entries that are not contained in a given timeframe

    HistoryTimeframeModel is a proxy model that filters the contents of a
    HistoryModel, excluding all entries that are not contained in a given
    timeframe specified by a start datetime and an end datetime.

    To leave one side of the timeframe open, do not set either the start or end
    datetime (or reset them to an invalid datetime).
*/
HistoryTimeframeModel::HistoryTimeframeModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryModel* HistoryTimeframeModel::sourceModel() const
{
    return qobject_cast<HistoryModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryTimeframeModel::setSourceModel(HistoryModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        beginResetModel();
        QSortFilterProxyModel::setSourceModel(sourceModel);
        endResetModel();
        Q_EMIT sourceModelChanged();
    }
}

const QDateTime& HistoryTimeframeModel::start() const
{
    return m_start;
}

void HistoryTimeframeModel::setStart(const QDateTime& start)
{
    if (start != m_start) {
        m_start = start;
        invalidate();
        Q_EMIT startChanged();
    }
}

const QDateTime& HistoryTimeframeModel::end() const
{
    return m_end;
}

void HistoryTimeframeModel::setEnd(const QDateTime& end)
{
    if (end != m_end) {
        m_end = end;
        invalidate();
        Q_EMIT endChanged();
    }
}

bool HistoryTimeframeModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QDateTime lastVisit = sourceModel()->data(index, HistoryModel::LastVisit).toDateTime();
    if (m_start.isValid() && (lastVisit < m_start)) {
        return false;
    }
    if (m_end.isValid() && (lastVisit > m_end)) {
        return false;
    }
    return true;
}

QHash<int, QByteArray> HistoryTimeframeModel::roleNames() const
{
    return (sourceModel()) ? sourceModel()->roleNames() : QHash<int, QByteArray>();
}
