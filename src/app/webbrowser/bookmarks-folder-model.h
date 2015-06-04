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

#ifndef __BOOKMARKS_FOLDER_MODEL_H__
#define __BOOKMARKS_FOLDER_MODEL_H__

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>

class BookmarksModel;

class BookmarksFolderModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(BookmarksModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged)

public:
    BookmarksFolderModel(QObject* parent=0);

    BookmarksModel* sourceModel() const;
    void setSourceModel(BookmarksModel* sourceModel);

    const QString& folder() const;
    void setFolder(const QString& domain);

Q_SIGNALS:
    void sourceModelChanged() const;
    void folderChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    QString m_folder;
};

#endif // __BOOKMARKS_FOLDER_MODEL_H__
