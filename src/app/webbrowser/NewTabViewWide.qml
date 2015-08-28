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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1
import ".."

FocusScope {
    id: newTabViewWide

    property QtObject bookmarksModel
    property alias historyModel: historyTimeframeModel.sourceModel
    property QtObject settingsObject
    property alias selectedIndex: sections.selectedIndex
    readonly property bool inBookmarksView: newTabViewWide.selectedIndex === 1

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)
    signal releasingKeyboardFocus()

    Keys.onTabPressed: selectedIndex = (selectedIndex + 1) % 2
    Keys.onBacktabPressed: selectedIndex = Math.abs((selectedIndex - 1) % 2)
    onActiveFocusChanged: {
        if (activeFocus) {
            if (inBookmarksView) {
                if (sections.lastFocusedBookmarksColumn === bookmarksList &&
                    bookmarksList.model.length === 0) {
                    sections.lastFocusedBookmarksColumn = folders
                }
                sections.lastFocusedBookmarksColumn.focus = true
            }
            else topSitesList.focus = true
        }
    }

    LimitProxyModel {
        id: topSitesModel
        limit: 10
        sourceModel: TopSitesModel {
            sourceModel: HistoryTimeframeModel {
                id: historyTimeframeModel
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#fbfbfb"
    }

    ListView {
        id: folders
        objectName: "foldersList"
        visible: inBookmarksView

        Keys.onRightPressed: if (bookmarksList.model.length > 0) bookmarksList.focus = true
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, folders.model.count - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewWide.releasingKeyboardFocus()
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                sections.lastFocusedBookmarksColumn = folders
                if (currentIndex < 0) currentIndex = 0
            }
        }

        anchors {
            top: sectionsGroup.bottom
            bottom: parent.bottom
            left: parent.left
            topMargin: units.gu(2)
        }
        width: units.gu(25)

        currentIndex: 0
        model: BookmarksFolderListModel {
            sourceModel: newTabViewWide.bookmarksModel
        }

        delegate: ListItem {
            id: folderItem
            objectName: "folderItem"
            property var model: entries
            property bool isActiveFolder: ListView.isCurrentItem
            property bool isCurrentItem: ListView.isCurrentItem
            property bool isAllBookmarksFolder: folder.length === 0
            property alias name: dropArea.folderName
            divider.visible: false

            property bool isCurrentDropTarget: dropArea.containsDrag && dropArea.drag.source.folder !== folder
            color: isCurrentDropTarget ? "green" :
                   ((folders.activeFocus && isActiveFolder) ? Qt.rgba(0, 0, 0, 0.05) : "transparent")

            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)

                fontSize: isAllBookmarksFolder ? "medium" : "small"
                text: isAllBookmarksFolder ? i18n.tr("All Bookmarks") : folderItem.name
                color: isActiveFolder ? UbuntuColors.orange : UbuntuColors.darkGrey
            }

            onClicked: folders.currentIndex = index

            DropArea {
                id: dropArea
                anchors.fill: parent
                property string folderName: folder
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
            top: sectionsGroup.bottom
            bottom: parent.bottom
            left: folders.right
            right: parent.right
            topMargin: units.gu(2)
        }
        visible: inBookmarksView
        onActiveFocusChanged: if (activeFocus) sections.lastFocusedBookmarksColumn = bookmarksList

        // Build a temporary model for the bookmarks list that includes, when
        // necessary, the homepage bookmark as a fixed first item in the list
        model: {
            if (!folders.currentItem) return null

            var items = []
            if (folders.currentItem.isAllBookmarksFolder) items.push({
                title: i18n.tr("Homepage"),
                url: newTabViewWide.settingsObject.homepage,
                folder: ""
            })

            if (!folders.currentItem.model) return null
            for (var i = 0; i < folders.currentItem.model.count; i++) {
                items.push(folders.currentItem.model.get(i))
            }
            return items
        }

        currentIndex: 0

        delegate: DraggableUrlDelegateWide {
            objectName: "bookmarkItem"
            clip: true

            title: modelData.title
            icon: modelData.icon ? modelData.icon : ""
            url: modelData.url

            property string folder: modelData.folder
            property bool isHomeBookmark: folder === "" && index === 0

            removable: !isHomeBookmark
            draggable: !isHomeBookmark && contentItem.x === 0
            highlighted: bookmarksList.activeFocus && ListView.isCurrentItem

            onClicked: newTabViewWide.bookmarkClicked(url)
            onRemoved: newTabViewWide.bookmarkRemoved(url)

            // Larger margin to prevent interference from Scrollbar hovering area
            gripMargin: units.gu(4)
            onDragStarted: {
                // Remove interactivity to prevent the list from scrolling
                // while dragging near its margins. This ensures we can correctly
                // return the item to its original position on a failed drop.
                bookmarksList.interactive = false

                // Relinquish focus as the presses and releases that compose the
                // drag will move the keyboard focus in a location unexpected
                // for the user. This way it will go back to the address bar and
                // the user can predictably resume keyboard interaction from there.
                newTabViewWide.releasingKeyboardFocus()
            }
            onDragEnded: {
                bookmarksList.interactive = true

                if (dragAndDrop.target && dragAndDrop.target.folderName !== folder) {
                    bookmarksModel.update(modelData.url, modelData.title,
                                          dragAndDrop.target.folderName)
                    dragAndDrop.success = true
                }
            }
        }

        Keys.onReturnPressed: newTabViewWide.bookmarkClicked(currentItem.url)
        Keys.onDeletePressed: {
            if (currentItem.removable) {
                newTabViewWide.bookmarkRemoved(currentItem.url)
                if (bookmarksList.model.length === 0) folders.focus = true
            }
        }
        Keys.onLeftPressed: folders.focus = true
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, model.length - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewWide.releasingKeyboardFocus()
        }
    }

    Scrollbar {
        flickableItem: bookmarksList
    }

    GridView {
        id: topSitesList
        objectName: "topSitesList"
        anchors {
            top: sectionsGroup.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            rightMargin: units.gu(4)
            leftMargin: units.gu(4)
        }

        visible: !inBookmarksView
        currentIndex: 0

        cellWidth: units.gu(17) + units.gu(4)
        cellHeight: units.gu(13) + units.gu(4)

        model: topSitesModel
        delegate: UrlPreviewDelegate {
            objectName: "topSiteItem"
            width: topSitesList.cellWidth
            height: topSitesList.cellHeight

            title: "[%1] %2".arg(model.visits).arg(model.title)
            icon: model.icon
            url: model.url
            highlighted: topSitesList.activeFocus && GridView.isCurrentItem

            onClicked: newTabViewWide.historyEntryClicked(url)
            onRemoved: newTabViewWide.historyModel.hide(url)
        }

        Keys.onReturnPressed: newTabViewWide.historyEntryClicked(currentItem.url)
        Keys.onDeletePressed: {
            newTabViewWide.historyModel.hide(currentItem.url)
            if (topSitesList.model.count === 0) newTabViewWide.releasingKeyboardFocus()
        }

        Keys.onLeftPressed: topSitesList.moveCurrentIndexLeft()
        Keys.onRightPressed: topSitesList.moveCurrentIndexRight()
        Keys.onDownPressed: topSitesList.moveCurrentIndexDown()
        Keys.onUpPressed: {
            var i = topSitesList.currentIndex
            topSitesList.moveCurrentIndexUp()
            if (i === topSitesList.currentIndex) newTabViewWide.releasingKeyboardFocus()
        }
    }

    Scrollbar {
        flickableItem: topSitesList
    }

    Rectangle {
        id: sectionsGroup
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        color: "#dedede"
        height: sections.height

        Sections {
            id: sections
            objectName: "sections"
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: units.gu(1)
            }

            selectedIndex: settingsObject.newTabDefaultSection
            onSelectedIndexChanged: {
                settingsObject.newTabDefaultSection = selectedIndex
                if (selectedIndex === 0) topSitesList.focus = true
                else {
                    if (lastFocusedBookmarksColumn) lastFocusedBookmarksColumn.focus = true
                    else folders.focus = true
                }

            }
            property var lastFocusedBookmarksColumn: folders

            actions: [
                Action { text: i18n.tr("Top sites") },
                Action { text: i18n.tr("Bookmarks") }
            ]
        }
    }
}
