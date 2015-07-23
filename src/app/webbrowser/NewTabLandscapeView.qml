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

import QtQuick 2.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1
import ".."

FocusScope {
    id: newTabViewLandscape

    property QtObject bookmarksModel
    property alias historyModel: historyTimeframeModel.sourceModel
    property Settings settingsObject
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
        color: "#f6f6f6"
    }

    Sections {
        id: sections

        selectedIndex: settingsObject.selectedIndexNewTabViewLandscape
        onSelectedIndexChanged: {
            settingsObject.selectedIndexNewTabViewLandscape = selectedIndex
            if (selectedIndex === 1) lastFocusedBookmarksColumn.focus = true
            else topSitesList.focus = true
        }
        property var lastFocusedBookmarksColumn: folders

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
        }

        actions: [
            Action { text: i18n.tr("Top Sites") },
            Action { text: i18n.tr("Bookmarks") }
        ]
    }

    ListView {
        id: folders
        visible: inBookmarksView
        property var activeFolder: null

        currentIndex: 0
        Keys.onReturnPressed: folders.activeFolder = currentItem
        Keys.onRightPressed: bookmarksColumn.focus = true
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, folders.model.count - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewLandscape.releasingKeyboardFocus()
        }
        onActiveFocusChanged: if (activeFocus) sections.lastFocusedBookmarksColumn = folders

        anchors {
            top: sections.bottom
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(25)

        model: BookmarksFolderListModel {
            sourceModel: newTabViewLandscape.bookmarksModel
        }

        delegate: ListItem {
            id: folderItem
            property var model: entries
            property bool isActiveFolder: folders.activeFolder === folderItem
            property bool isCurrentItem: ListView.isCurrentItem
            property bool isAllBookmarksFolder: folder.length === 0

            color: folders.activeFocus && ListView.isCurrentItem ? Qt.rgba(0, 0, 0, 0.05) : "transparent"

            Component.onCompleted: {
                if (isAllBookmarksFolder && !folders.activeFolder) folders.activeFolder = folderItem
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)

                fontSize: "small"
                text: isAllBookmarksFolder ? i18n.tr("All Bookmarks") : folder
                color: isCurrentItem || isActiveFolder ? UbuntuColors.orange : "black"
            }

            onClicked: folders.activeFolder = folderItem
        }
    }

    Flickable {
        anchors {
            top: sections.bottom
            bottom: parent.bottom
            left: inBookmarksView ? folders.right : parent.left
            right: parent.right
        }
        contentHeight: contentColumn.height

        clip: true

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height

            Column {
                id: bookmarksColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }

                property int cursorIndex: 0
                Keys.onLeftPressed: folders.focus = true
                Keys.onDownPressed: cursorIndex = Math.min(cursorIndex + 1, bookmarksList.model.count)
                Keys.onUpPressed: {
                    if (cursorIndex > 0) cursorIndex = Math.max(cursorIndex - 1, 0)
                    else newTabViewLandscape.releasingKeyboardFocus()
                }
                onActiveFocusChanged: if (activeFocus) sections.lastFocusedBookmarksColumn = bookmarksColumn
                Keys.onReturnPressed: {
                    if (cursorIndex === 0) newTabViewLandscape.bookmarkClicked(homePageBookmark.url)
                    else newTabViewLandscape.bookmarkClicked(bookmarksList.highlightedUrl)
                }

                visible: inBookmarksView

                height: childrenRect.height
                spacing: 0

                UrlDelegate {
                    id: homePageBookmark
                    objectName: "homepageBookmark"
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(5)

                    title: i18n.tr('Homepage')

                    leadingActions: null

                    url: newTabViewLandscape.settingsObject.homepage
                    onClicked: newTabViewLandscape.bookmarkClicked(url)
                    visible: folders.activeFolder ? folders.activeFolder.isAllBookmarksFolder : false
                    highlighted: bookmarksColumn.activeFocus && bookmarksColumn.cursorIndex == 0
                }

                UrlsList {
                    id: bookmarksList
                    objectName: "bookmarksList"
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 0
                    limit: 10
                    highlightedIndex: bookmarksColumn.activeFocus ? bookmarksColumn.cursorIndex - 1 : -1

                    model: folders.activeFolder ? folders.activeFolder.model : null

                    onUrlClicked: newTabViewLandscape.bookmarkClicked(url)
                    onUrlRemoved: newTabViewLandscape.bookmarkRemoved(url)
                }
            }

            Label {
                objectName: "notopsites"

                height: units.gu(11)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: !inBookmarksView && topSitesModel.count == 0

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: i18n.tr("You haven't visited any site yet")
                color: "#5d5d5d"
            }

            UrlsList {
                id: topSitesList
                objectName: "topSitesList"
                anchors {
                    left: parent.left
                    right: parent.right
                }

                property int cursorIndex: 0
                highlightedIndex: activeFocus ? cursorIndex : -1
                Keys.onReturnPressed: newTabViewLandscape.historyEntryClicked(highlightedUrl)
                Keys.onDownPressed: cursorIndex = Math.min(cursorIndex + 1, topSitesList.model.count - 1)
                Keys.onUpPressed: {
                    if (cursorIndex > 0) cursorIndex = Math.max(cursorIndex - 1, 0)
                    else newTabViewLandscape.releasingKeyboardFocus()
                }

                opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation {} }
                visible: !inBookmarksView

                spacing: 0

                model: topSitesModel

                onUrlClicked: newTabViewLandscape.historyEntryClicked(url)
                onUrlRemoved: newTabViewLandscape.historyModel.hide(url)
            }
        }
    }
}
