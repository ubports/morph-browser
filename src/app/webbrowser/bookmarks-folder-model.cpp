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

#include "bookmarks-folder-model.h"
#include "bookmarks-model.h"

// Qt
#include <QtCore/QUrl>

/*!
    \class BookmarksFolderModel
    \brief Proxy model that filters the contents of a bookmarks model
           based on a folder name

    BookmarksFolderModel is a proxy model that filters the contents of a
    bookmarks model based on a folder name.

    An entry in the bookmarks model matches if it is stored in a folder
    with the same name that the filter folder name (case-sensitive
    comparison).

    When no folder name is set (null or empty string), all entries that 
    are not stored in any folder match.
*/

BookmarksFolderModel::BookmarksFolderModel(QObject* parent)
    : QSortFilterProxyModel(parent)
{
    connect(this, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)), SLOT(onModelChanged()));
    connect(this, SIGNAL(modelReset()), SLOT(onModelChanged()));
    connect(this, SIGNAL(rowsInserted(QModelIndex, int, int)), SLOT(onModelChanged()));
    connect(this, SIGNAL(rowsRemoved(QModelIndex, int, int)), SLOT(onModelChanged()));
    connect(this, SIGNAL(dataChanged(QModelIndex, QModelIndex, QVector<int>)), SLOT(onModelChanged()));
}

BookmarksModel* BookmarksFolderModel::sourceModel() const
{
    return qobject_cast<BookmarksModel*>(QSortFilterProxyModel::sourceModel());
}

void BookmarksFolderModel::setSourceModel(BookmarksModel* sourceModel)
{
    if (sourceModel != this->sourceModel()) {
        QSortFilterProxyModel::setSourceModel(sourceModel);
        Q_EMIT sourceModelChanged();
    }
}

const QString& BookmarksFolderModel::folder() const
{
    return m_folder;
}

void BookmarksFolderModel::setFolder(const QString& folder)
{
    if (folder != m_folder) {
        m_folder = folder;
        invalidate();
        Q_EMIT folderChanged();
    }
}

const QDateTime& BookmarksFolderModel::lastAddition() const
{
    return m_lastAddition;
}

bool BookmarksFolderModel::filterAcceptsRow(int source_row, const QModelIndex& source_parent) const
{
    QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
    QString folder = sourceModel()->data(index, BookmarksModel::Folder).toString();
    return (folder.compare(m_folder, Qt::CaseSensitive) == 0);
}

void BookmarksFolderModel::onModelChanged()
{
    // If the rowCount is zero all the bookmarks entries of this model were
    // removed. If that happens this folder will be removed from the list, so
    // we shouldn’t update its properties lest the update triggers a re-ordering
    // on any sort proxy model that uses this model as source, while removing an
    // entry.
    if (rowCount() > 0) {
        m_lastAddition = data(index(0, 0), BookmarksModel::Created).toDateTime();

        Q_EMIT lastAdditionChanged();
    }
}
