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

import QtQuick 2.4
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1

FocusScope {
    id: bookmarksFoldersViewWideItem

    property alias model: bookmarksFolderListModel.sourceModel 
    property url homeBookmarkUrl

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal dragStarted()

    function restoreLastFocusedColumn() {
        if (internal.lastFocusedColumn &&
            internal.lastFocusedColumn == bookmarksList &&
            model.count > 0) {

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

    Rectangle {
        anchors.fill: parent
        color: "#fbfbfb"
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
        }
        currentIndex: 0

        Keys.onRightPressed: {
            if (bookmarksList.model.length > 0) {
                bookmarksList.focus = true
            }
        }

        delegate: ListItem {
            id: folderItem
            objectName: "folderItem"

            property alias name: dropArea.folderName
            property bool isActiveFolder: ListView.isCurrentItem
            property bool isAllBookmarksFolder: folder.length === 0
            property bool isCurrentDropTarget: dropArea.containsDrag && dropArea.drag.source.folder !== folder
            property var model: entries

            divider.visible: false

            color: isCurrentDropTarget ? "green" :
                   ((folders.activeFocus && isActiveFolder) ? Qt.rgba(0, 0, 0, 0.05) : "transparent")

            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }

                fontSize: isAllBookmarksFolder ? "medium" : "small"
                text: isAllBookmarksFolder ? i18n.tr("All Bookmarks") : folderItem.name
                color: isActiveFolder ? UbuntuColors.orange : UbuntuColors.darkGrey
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
                internal.lastFocusedColumn = bookmarksList
            }
        }

        // Build a temporary model for the bookmarks list that includes, when
        // necessary, the homepage bookmark as a fixed first item in the list
        model: {
            if (!folders.currentItem || !folders.currentItem.model) {
                return null
            }

            var items = []
            if (folders.currentItem.isAllBookmarksFolder) {
                items.push({
                    title: i18n.tr("Homepage"),
                    url: bookmarksFoldersViewWideItem.homeBookmarkUrl,
                    folder: ""
                })
            }

            for (var i = 0; i < folders.currentItem.model.count; i++) {
                items.push(folders.currentItem.model.get(i))
            }

            return items
        }

        currentIndex: 0

        delegate: DraggableUrlDelegateWide {
            objectName: "bookmarkItem"

            property string folder: modelData.folder
            property bool isHomeBookmark: folder === "" && index === 0

            clip: true
            title: modelData.title
            icon: modelData.icon ? modelData.icon : ""
            url: modelData.url

            removable: !isHomeBookmark
            draggable: !isHomeBookmark && contentItem.x === 0
            highlighted: bookmarksList.activeFocus && ListView.isCurrentItem

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
                    bookmarksFoldersViewWideItem.model.update(modelData.url, modelData.title,
                                                                 dragAndDrop.target.folderName)
                    dragAndDrop.success = true
                }
            }
        }

        Keys.onReturnPressed: bookmarksFoldersViewWideItem.bookmarkClicked(currentItem.url)
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
