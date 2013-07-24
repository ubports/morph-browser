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

#include "domain-utils.h"
#include "history-domain-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"

// Qt
#include <QtCore/QUrl>

/*!
    \class HistoryDomainModel
    \brief Proxy model that filters the contents of a history model
           based on a domain name

    HistoryDomainModel is a proxy model that filters the contents of a
    history model based on a domain name.

    An entry in the history model matches if the domain name extracted from
    its URL equals the filter domain name (case-insensitive comparison).

    When no domain name is set (null or empty string), all entries match.
*/
HistoryDomainModel::HistoryDomainModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryTimeframeModel* HistoryDomainModel::sourceModel() const
{
    return qobject_cast<HistoryTimeframeModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryDomainModel::setSourceModel(HistoryTimeframeModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QString& HistoryDomainModel::domain() const
{
    return m_domain;
}

void HistoryDomainModel::setDomain(const QString& domain)
{
    if (domain != m_domain) {
        m_domain = domain;
        invalidateFilter();
        Q_EMIT domainChanged();
    }
}

bool HistoryDomainModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_domain.isEmpty()) {
        return true;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QUrl url = sourceModel()->data(index, HistoryModel::Url).toUrl();
    QString domain = DomainUtils::extractTopLevelDomainName(url);
    return (domain.compare(m_domain, Qt::CaseInsensitive) == 0);
}

// reimplemented for debugging purposes
#include <QDebug>
QVariant HistoryDomainModel::data(const QModelIndex& index, int role) const
{
    QVariant d = QSortFilterProxyModel::data(index, role);
    //qDebug() << Q_FUNC_INFO << index << role << d;
    return d;
}
