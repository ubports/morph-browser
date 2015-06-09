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
#include "bookmarks-folderlist-model.h"
#include "bookmarks-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtCore/QStringList>

/*!
    \class BookmarksFolderListModel
    \brief List model that exposes bookmarks entries grouped by folder name

    BookmarksFolderListModel is a list model that exposes bookmarks entries
    from a BookmarksModel grouped by folder name. Each item in the list has
    three roles: 'folder' for the folder name and 'entries' for the
    corresponding BookmarksFolderModel that contains all entries in this group.
*/
BookmarksFolderListModel::BookmarksFolderListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_sourceModel(0)
{
}

BookmarksFolderListModel::~BookmarksFolderListModel()
{
    clearFolders();
}

QHash<int, QByteArray> BookmarksFolderListModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Folder] = "folder";
        roles[Entries] = "entries";
    }
    return roles;
}

int BookmarksFolderListModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_folders.count();
}

QVariant BookmarksFolderListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const QString folder = m_folders.keys().at(index.row());
    BookmarksFolderModel* entries = m_folders.value(folder);

    switch (role) {
    case Folder:
        return folder;
    case Entries:
        return QVariant::fromValue(entries);
    default:
        return QVariant();
    }
}

BookmarksModel* BookmarksFolderListModel::sourceModel() const
{
    return m_sourceModel;
}

void BookmarksFolderListModel::setSourceModel(BookmarksModel* sourceModel)
{
    if (sourceModel != m_sourceModel) {
        beginResetModel();
        if (m_sourceModel != 0) {
            m_sourceModel->disconnect(this);
        }
        clearFolders();
        m_sourceModel = sourceModel;
        populateModel();
        if (m_sourceModel != 0) {
            connect(m_sourceModel, SIGNAL(folderAdded(const QString&)), SLOT(onFolderAdded(const QString&)));
            connect(m_sourceModel, SIGNAL(modelReset()), SLOT(onModelReset()));
        }
        endResetModel();
        Q_EMIT sourceModelChanged();
    }
}

QVariantMap BookmarksFolderListModel::get(int row) const
{
    if (!checkValidFolderIndex(row)) {
        return QVariantMap();
    }

    QVariantMap res;
    QHash<int,QByteArray> names = roleNames();
    QHashIterator<int, QByteArray> i(names);

    while (i.hasNext()) {
        i.next();
        QModelIndex idx = index(row, 0);
        QVariant data = idx.data(i.key());
        res[i.value()] = data;
    }

    return res;
}

int BookmarksFolderListModel::indexOf(const QString& folder) const
{
    QStringList folders = m_folders.keys();
    return folders.indexOf(folder);
}

void BookmarksFolderListModel::createNewFolder(const QString& folder)
{
    m_sourceModel->addFolder(folder);
}

bool BookmarksFolderListModel::checkValidFolderIndex(int index) const
{
    if ((index < 0) || (index >= m_folders.count())) {
        qWarning() << "Invalid folder index:" << index;
        return false;
    }
    return true;
}

void BookmarksFolderListModel::clearFolders()
{
    Q_FOREACH(const QString& folder, m_folders.keys()) {
        delete m_folders.take(folder);
    }
}

void BookmarksFolderListModel::populateModel()
{
    if (m_sourceModel != 0) {
        Q_FOREACH(const QString& folder, m_sourceModel->folders()) {
            if (!m_folders.contains(folder)) {
                addFolder(folder);
            }
        }
    }
}

void BookmarksFolderListModel::onFolderAdded(const QString& folder)
{
    if (!m_folders.contains(folder)) {
        QStringList folders = m_folders.keys();
        int insertAt = 0;
        while (insertAt < folders.count()) {
            if (folder.compare(folders.at(insertAt)) < 0) {
                break;
            }
            ++insertAt;
        }
        beginInsertRows(QModelIndex(), insertAt, insertAt);
        addFolder(folder);
        endInsertRows();
    }
}

void BookmarksFolderListModel::onModelReset()
{
    beginResetModel();
    clearFolders();
    populateModel();
    endResetModel();
}

void BookmarksFolderListModel::addFolder(const QString& folder)
{
    BookmarksFolderModel* model = new BookmarksFolderModel(this);
    model->setSourceModel(m_sourceModel);
    model->setFolder(folder);
    connect(model, SIGNAL(rowsInserted(QModelIndex, int, int)), SLOT(onFolderDataChanged()));
    connect(model, SIGNAL(rowsRemoved(QModelIndex, int, int)), SLOT(onFolderDataChanged()));
    connect(model, SIGNAL(rowsMoved(QModelIndex, int, int, QModelIndex, int)), SLOT(onFolderDataChanged()));
    connect(model, SIGNAL(layoutChanged(QList<QPersistentModelIndex>, QAbstractItemModel::LayoutChangeHint)), SLOT(onFolderDataChanged()));
    connect(model, SIGNAL(dataChanged(QModelIndex, QModelIndex)), SLOT(onFolderDataChanged()));
    connect(model, SIGNAL(modelReset()), SLOT(onFolderDataChanged()));
    m_folders.insert(folder, model);
}

QString BookmarksFolderListModel::getFolderFromSourceModel(const QModelIndex& index) const
{
    return m_sourceModel->data(index, BookmarksModel::Folder).toString();
}

void BookmarksFolderListModel::onFolderDataChanged()
{
    BookmarksFolderModel* model = qobject_cast<BookmarksFolderModel*>(sender());
    if (model != 0) {
        emitDataChanged(model->folder());
    }
}

void BookmarksFolderListModel::emitDataChanged(const QString& folder)
{
    int i = m_folders.keys().indexOf(folder);
    if (i != -1) {
        QModelIndex index = this->index(i, 0);
        Q_EMIT dataChanged(index, index, QVector<int>() << Entries);
    }
}
