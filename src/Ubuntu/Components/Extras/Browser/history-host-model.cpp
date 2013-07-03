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

#include "history-host-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QUrl>

/*!
    \class HistoryHostModel
    \brief Proxy model that filters the contents of a history model
           based on a host name

    HistoryHostModel is a proxy model that filters the contents of a
    history model based on a host name.

    An entry in the history model matches if its URL’s host equals the filter
    host (case-insensitive comparison).

    When no host is set (null string), all entries match.
    A non-null, empty host matches all the entries with an empty host, that is,
    entries corresponding to local files.
*/
HistoryHostModel::HistoryHostModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryTimeframeModel* HistoryHostModel::sourceModel() const
{
    return qobject_cast<HistoryTimeframeModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryHostModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QString& HistoryHostModel::host() const
{
    return m_host;
}

void HistoryHostModel::setHost(const QString& host)
{
    if ((host != m_host)
            || (m_host.isNull() && !host.isNull())
            || (!m_host.isNull() && host.isNull())) {
        m_host = host;
        invalidateFilter();
        Q_EMIT hostChanged();
    }
}

bool HistoryHostModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_host.isNull()) {
        return true;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QUrl url = sourceModel()->data(index, HistoryModel::Url).toUrl();
    return (url.host().compare(m_host, Qt::CaseInsensitive) == 0);
}
