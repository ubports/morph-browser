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

#include "bookmarks-chronological-maxcount-model.h"
#include "bookmarks-chronological-model.h"
#include "bookmarks-model.h"

/*!
    \class BookmarksChronologicalMaxCountModel
    \brief Proxy model that limits the number of rows returned by a bookmarks
    model in chronological order

    BookmarksChronologicalMaxCountModel is a proxy model that limits the number
    of rows returned by a BookmarksChronologicalModel
    (i.e. only the first N bookmarks are returned).
*/
BookmarksChronologicalMaxCountModel::BookmarksChronologicalMaxCountModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);

    m_maxCount = -1;
}

BookmarksChronologicalModel* BookmarksChronologicalMaxCountModel::sourceModel() const
{
    return qobject_cast<BookmarksChronologicalModel*>(QSortFilterProxyModel::sourceModel());
}

void BookmarksChronologicalMaxCountModel::setSourceModel(BookmarksChronologicalModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

int BookmarksChronologicalMaxCountModel::maxCount() const
{
    return m_maxCount;
}

void BookmarksChronologicalMaxCountModel::setMaxCount(int count)
{
    if (count != m_maxCount) {
        m_maxCount = count;
        invalidate();
        Q_EMIT maxCountChanged();
    }
}

bool BookmarksChronologicalMaxCountModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    Q_UNUSED(source_parent);

    if (m_maxCount >= 0 && source_row >= m_maxCount)
        return false;
    return true;
}
