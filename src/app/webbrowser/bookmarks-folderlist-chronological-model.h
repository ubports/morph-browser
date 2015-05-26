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

#ifndef __BOOKMARKS_FOLDERLIST_CHRONOLOGICAL_MODEL_H__
#define __BOOKMARKS_FOLDERLIST_CHRONOLOGICAL_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>

class BookmarksFolderListModel;

class BookmarksFolderListChronologicalModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(BookmarksFolderListModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)

public:
    BookmarksFolderListChronologicalModel(QObject* parent=0);

    BookmarksFolderListModel* sourceModel() const;
    void setSourceModel(BookmarksFolderListModel* sourceModel);

Q_SIGNALS:
    void sourceModelChanged() const;
};

#endif // __BOOKMARKS_FOLDERLIST_CHRONOLOGICAL_MODEL_H__
