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

#include "history-matches-model.h"
#include "history-model.h"

// Qt
#include <QtCore/QRegExp>

/*!
    \class HistoryMatchesModel
    \brief Proxy model that filters the contents of the history model
           based on a query string

    HistoryMatchesModel is a proxy model that filters the contents of a
    HistoryModel based on a query string.

    The query string may contain several terms (or words).

    An entry in the history model matches if all the terms are contained in
    either its URL or its title (inclusive OR).
*/
HistoryMatchesModel::HistoryMatchesModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

HistoryModel* HistoryMatchesModel::sourceModel() const
{
    return qobject_cast<HistoryModel*>(QSortFilterProxyModel::sourceModel());
}

void HistoryMatchesModel::setSourceModel(HistoryModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QString& HistoryMatchesModel::query() const
{
    return m_query;
}

void HistoryMatchesModel::setQuery(const QString& query)
{
    if (query != m_query) {
        m_query = query;
        m_terms = query.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        invalidateFilter();
        Q_EMIT queryChanged();
        Q_EMIT termsChanged();
    }
}

const QStringList& HistoryMatchesModel::terms() const
{
    return m_terms;
}

bool HistoryMatchesModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_terms.isEmpty()) {
        return false;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QString url = sourceModel()->data(index, HistoryModel::Url).toUrl().toString();
    QString title = sourceModel()->data(index, HistoryModel::Title).toString();
    Q_FOREACH (const QString& term, m_terms) {
        if (!url.contains(term, Qt::CaseInsensitive) &&
            !title.contains(term, Qt::CaseInsensitive)) {
            return false;
        }
    }
    return true;
}
