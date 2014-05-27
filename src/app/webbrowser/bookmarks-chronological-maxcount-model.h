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

#ifndef __BOOKMARKS_CHRONOLOGICAL_MAXCOUNT_MODEL_H__
#define __BOOKMARKS_CHRONOLOGICAL_MAXCOUNT_MODEL_H__

// Qt
#include <QtCore/QSortFilterProxyModel>

class BookmarksChronologicalModel;

class BookmarksChronologicalMaxCountModel : public QSortFilterProxyModel
{
    Q_OBJECT

    Q_PROPERTY(BookmarksChronologicalModel* sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(int maxCount READ maxCount WRITE setMaxCount NOTIFY maxCountChanged)
    Q_PROPERTY(int count READ rowCount)

public:
    BookmarksChronologicalMaxCountModel(QObject* parent=0);

    BookmarksChronologicalModel* sourceModel() const;
    void setSourceModel(BookmarksChronologicalModel* sourceModel);

    int maxCount() const;
    void setMaxCount(int count);

Q_SIGNALS:
    void sourceModelChanged() const;
    void maxCountChanged() const;

protected:
    // reimplemented from QSortFilterProxyModel
    bool filterAcceptsRow(int source_row, const QModelIndex& source_parent) const;

private:
    int m_maxCount;
};

#endif // __BOOKMARKS_CHRONOLOGICAL_MAXCOUNT_MODEL_H__
