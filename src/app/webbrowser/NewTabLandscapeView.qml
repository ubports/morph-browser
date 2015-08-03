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
    id: newTabViewLandscape

    property QtObject bookmarksModel
    property alias historyModel: historyTimeframeModel.sourceModel
    property QtObject settingsObject
    property alias selectedIndex: sections.selectedIndex
    property bool inBookmarksView: newTabViewLandscape.selectedIndex === 1

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)
    signal releasingKeyboardFocus()

    Keys.onTabPressed: selectedIndex = (selectedIndex + 1) % 2
    Keys.onBacktabPressed: selectedIndex = Math.abs((selectedIndex - 1) % 2)
    onActiveFocusChanged: {
        if (activeFocus) {
            if (inBookmarksView) sections.lastFocusedBookmarksColumn.focus = true
            else topSitesList.focus = true
        }
    }

    TopSitesModel {
        id: topSitesModel
        sourceModel: HistoryTimeframeModel {
            id: historyTimeframeModel
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
            else newTabViewLandscape.releasingKeyboardFocus()
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
            sourceModel: newTabViewLandscape.bookmarksModel
        }

        delegate: ListItem {
            id: folderItem
            objectName: "folderItem"
            property var model: entries
            property bool isActiveFolder: ListView.isCurrentItem
            property bool isCurrentItem: ListView.isCurrentItem
            property bool isAllBookmarksFolder: folder.length === 0
            divider.visible: false

            color: (folders.activeFocus && isActiveFolder) ? Qt.rgba(0, 0, 0, 0.05) : "transparent"

            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)

                fontSize: isAllBookmarksFolder ? "medium" : "small"
                text: isAllBookmarksFolder ? i18n.tr("All Bookmarks") : folder
                color: isCurrentItem || isActiveFolder ? UbuntuColors.orange : "black"
            }

            onClicked: folders.currentIndex = index
        }
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
                url: newTabViewLandscape.settingsObject.homepage
            })

            if (!folders.currentItem.model) return null
            for (var i = 0; i < folders.currentItem.model.count; i++) {
                items.push(folders.currentItem.model.get(i))
            }
            return items
        }

        currentIndex: 0

        delegate: UrlDelegateLandscape {
            objectName: "bookmarkItem"
            title: modelData.title
            icon: modelData.icon ? modelData.icon : ""
            url: modelData.url
            removable: !folders.currentItem.isAllBookmarksFolder || index > 0
            highlighted: bookmarksList.activeFocus && ListView.isCurrentItem

            onClicked: newTabViewLandscape.bookmarkClicked(url)
            onRemoved: newTabViewLandscape.bookmarkRemoved(url)
        }

        Keys.onReturnPressed: newTabViewLandscape.bookmarkClicked(currentItem.url)
        Keys.onDeletePressed: if (currentItem.removable) newTabViewLandscape.bookmarkRemoved(currentItem.url)
        Keys.onLeftPressed: folders.focus = true
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, model.length - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewLandscape.releasingKeyboardFocus()
        }
    }

    ListView {
        id: topSitesList
        objectName: "topSitesList"
        anchors {
            top: sectionsGroup.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: units.gu(2)
        }

        visible: !inBookmarksView
        currentIndex: 0

        model: topSitesModel
        delegate: UrlDelegateLandscape {
            objectName: "topSiteItem"
            title: model.title
            icon: model.icon
            url: model.url
            highlighted: topSitesList.activeFocus && ListView.isCurrentItem

            onClicked: newTabViewLandscape.historyEntryClicked(url)
            onRemoved: newTabViewLandscape.historyModel.hide(url)
        }

        Keys.onReturnPressed: newTabViewLandscape.historyEntryClicked(currentItem.url)
        Keys.onDeletePressed: newTabViewLandscape.historyModel.hide(currentItem.url)
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, model.count - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewLandscape.releasingKeyboardFocus()
        }
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

            selectedIndex: settingsObject.selectedIndexNewTabViewLandscape
            onSelectedIndexChanged: {
                settingsObject.selectedIndexNewTabViewLandscape = selectedIndex
                if (selectedIndex === 0) topSitesList.focus = true
                else {
                    if (lastFocusedBookmarksColumn) lastFocusedBookmarksColumn.focus = true
                    else folders.focus = true
                }

            }
            property var lastFocusedBookmarksColumn: folders

            actions: [
                Action { text: i18n.tr("Top Sites") },
                Action { text: i18n.tr("Bookmarks") }
            ]
        }
    }
}
