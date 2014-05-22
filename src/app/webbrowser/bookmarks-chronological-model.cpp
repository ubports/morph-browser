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

#include "bookmarks-chronological-model.h"
#include "bookmarks-model.h"

/*!
    \class BookmarksChronologicalModel
    \brief Proxy model that sorts a bookmarks model in chronological order

    BookmarksChronologicalModel is a proxy model that sorts a
    BookmarksModel in chronological order
    (i.e. the bookmark with the newest added date first).
*/
BookmarksChronologicalModel::BookmarksChronologicalModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortRole(BookmarksModel::BookmarkedAt);
    sort(0, Qt::DescendingOrder);
}

BookmarksModel* BookmarksChronologicalModel::sourceModel() const
{
    return qobject_cast<BookmarksModel*>(QSortFilterProxyModel::sourceModel());
}

void BookmarksChronologicalModel::setSourceModel(BookmarksModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}
