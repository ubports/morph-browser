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

#include "bookmarks-matches-model.h"
#include "bookmarks-model.h"

// Qt
#include <QtCore/QRegExp>

/*!
    \class BookmarksMatchesModel
    \brief Proxy model that filters the contents of the bookmarks model
           based on a query string

    BookmarksMatchesModel is a proxy model that filters the contents of a
    BookmarksModel based on a query string.

    The query string may contain several terms (or words).

    An entry in the bookmarks model matches if all the terms are contained in
    either its URL or its title (inclusive OR).
*/
BookmarksMatchesModel::BookmarksMatchesModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
}

BookmarksModel* BookmarksMatchesModel::sourceModel() const
{
    return qobject_cast<BookmarksModel*>(QSortFilterProxyModel::sourceModel());
}

void BookmarksMatchesModel::setSourceModel(BookmarksModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
        Q_EMIT countChanged();
    }
}

const QString& BookmarksMatchesModel::query() const
{
    return m_query;
}

void BookmarksMatchesModel::setQuery(const QString& query)
{
    if (query != m_query) {
        m_query = query;
        m_terms = query.split(QRegExp("\\s+"), QString::SkipEmptyParts);
        invalidateFilter();
        Q_EMIT queryChanged();
        Q_EMIT termsChanged();
        Q_EMIT countChanged();
    }
}

const QStringList& BookmarksMatchesModel::terms() const
{
    return m_terms;
}

bool BookmarksMatchesModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    if (m_terms.isEmpty()) {
        return false;
    }
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QString url = sourceModel()->data(index, BookmarksModel::Url).toUrl().toString();
    QString title = sourceModel()->data(index, BookmarksModel::Title).toString();
    Q_FOREACH (const QString& term, m_terms) {
        if (!url.contains(term, Qt::CaseInsensitive) &&
            !title.contains(term, Qt::CaseInsensitive)) {
            return false;
        }
    }
    return true;
}

int BookmarksMatchesModel::count() const
{
    return rowCount();
}

QVariantMap BookmarksMatchesModel::get(int index) const
{
    QVariantMap item;
    Q_FOREACH(int role, sourceModel()->roleNames().keys()) {
        QString propertyName = sourceModel()->roleNames()[role];
        QModelIndex modelIndex = sourceModel()->index(index);
        item.insert(propertyName, sourceModel()->data(modelIndex, role));
    }
    return item;
}
