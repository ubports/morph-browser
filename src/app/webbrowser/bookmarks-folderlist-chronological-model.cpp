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

#include "bookmarks-folderlist-chronological-model.h"
#include "bookmarks-folderlist-model.h"

/*!
    \class BookmarksFolderListChronologicalModel
    \brief Proxy model that sorts a folder list model in reverse chronological
           order

    BookmarksFolderListChronologicalModel is a proxy model that sorts a
    BookmarksFolderListModel in reverse chronological order
    (i.e. the latest bookmarked url first).
*/
BookmarksFolderListChronologicalModel::BookmarksFolderListChronologicalModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortRole(BookmarksFolderListModel::LastAddition);
    sort(0, Qt::DescendingOrder);
}

BookmarksFolderListModel* BookmarksFolderListChronologicalModel::sourceModel() const
{
    return qobject_cast<BookmarksFolderListModel*>(QSortFilterProxyModel::sourceModel());
}

void BookmarksFolderListChronologicalModel::setSourceModel(BookmarksFolderListModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}
