/*
 * Copyright 2015-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1
import "BookmarksModelUtils.js" as BookmarksModelUtils

FocusScope {
    id: bookmarksFoldersViewWideItem

    property url homeBookmarkUrl

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal dragStarted()

    function restoreLastFocusedColumn() {
        if (internal.lastFocusedColumn &&
            internal.lastFocusedColumn == bookmarksList &&
            BookmarksModel.count > 0) {
            bookmarksList.forceActiveFocus()
        } else {
            folders.forceActiveFocus()
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            restoreLastFocusedColumn()
        }
    }

    ListView {
        id: folders
        objectName: "foldersList"

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }

        width: units.gu(25)

        onActiveFocusChanged: {
            if (activeFocus) {
                internal.lastFocusedColumn = folders
            }
        }

        model: BookmarksFolderListModel {
            id: bookmarksFolderListModel
            sourceModel: BookmarksModel
        }
        currentIndex: 0

        Keys.onRightPressed: {
            if (!folders.currentItem) {
                return
            }

            if ((folders.currentItem.isAllBookmarksFolder && bookmarksList.model.length > 0) || bookmarksList.model.count > 0) {
                bookmarksList.focus = true
            }
        }

        delegate: ListItem {
            id: folderItem
            objectName: "folderItem"

            property alias name: dropArea.folderName
            property var model: entries
            readonly property bool isActiveFolder: ListView.isCurrentItem
            readonly property bool isAllBookmarksFolder: folder.length === 0
            readonly property bool isCurrentDropTarget: dropArea.containsDrag && dropArea.drag.source.folder !== folder

            color: isCurrentDropTarget ? theme.palette.normal.positive : "transparent"

            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }

                fontSize: "small"
                text: isAllBookmarksFolder ? i18n.tr("All Bookmarks") : folderItem.name
                color: (isActiveFolder && !folders.activeFocus) ? theme.palette.normal.positionText : theme.palette.normal.backgroundSecondaryText
            }

            onClicked: folders.currentIndex = index

            DropArea {
                id: dropArea

                property string folderName: folder
                anchors.fill: parent
            }
        }
    }

    Scrollbar {
        flickableItem: folders
    }

    ListView {
        id: bookmarksList
        objectName: "bookmarksList"

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: folders.right
            right: parent.right
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                internal.lastFocusedColumn = bookmarksList;
            }
        }

        model: {
            if (!folders.currentItem || !folders.currentItem.model) {
                return null;
            }

            if (folders.currentItem.isAllBookmarksFolder && (homeBookmarkUrl.toString() !== "")) {
                return BookmarksModelUtils.prependHomepageToBookmarks(folders.currentItem.model, {
                    title: i18n.tr("Homepage"),
                    url: homeBookmarkUrl,
                    folder: ""
                });
            }

            return folders.currentItem.model;
        }

        currentIndex: 0

        delegate: DraggableUrlDelegateWide {
            objectName: "bookmarkItem"

            property var entry: (folders.currentItem.isAllBookmarksFolder && (homeBookmarkUrl.toString() !== "")) ? modelData : model
            property string folder: entry.folder
            readonly property bool isHomeBookmark: (homeBookmarkUrl.toString() !== "") && (folder === "") && (index === 0)

            clip: true
            title: entry.title
            icon: entry.icon ? entry.icon : ""
            url: entry.url

            removable: !isHomeBookmark
            draggable: !isHomeBookmark && contentItem.x === 0

            onClicked: bookmarksFoldersViewWideItem.bookmarkClicked(url)
            onRemoved: bookmarksFoldersViewWideItem.bookmarkRemoved(url)

            // Larger margin to prevent interference from Scrollbar hovering area
            gripMargin: units.gu(4)
            onDragStarted: {
                // Remove interactivity to prevent the list from scrolling
                // while dragging near its margins. This ensures we can correctly
                // return the item to its original position on a failed drop.
                bookmarksList.interactive = false

                bookmarksFoldersViewWideItem.dragStarted()
            }
            onDragEnded: {
                bookmarksList.interactive = true

                if (dragAndDrop.target && dragAndDrop.target.folderName !== folder) {
                    BookmarksModel.update(entry.url, entry.title, dragAndDrop.target.folderName)
                    dragAndDrop.success = true
                }
            }
        }

        Keys.onDeletePressed: {
            if (currentItem.removable) {
                bookmarksFoldersViewWideItem.bookmarkRemoved(currentItem.url)
                if (bookmarksList.model.length === 0) {
                    folders.focus = true
                }
            }
        }
        Keys.onLeftPressed: folders.focus = true
    }

    Scrollbar {
        flickableItem: bookmarksList
    }

    QtObject {
        id: internal

        property var lastFocusedColumn: folders
    }
}
