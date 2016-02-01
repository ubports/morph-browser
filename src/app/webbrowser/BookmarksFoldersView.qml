/*
 * Copyright 2015-2016 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItem
import webbrowserapp.private 0.1
import "BookmarksModelUtils.js" as BookmarksModelUtils

FocusScope {
    id: bookmarksFoldersViewItem

    property alias interactive: bookmarksFolderListView.interactive
    property url homeBookmarkUrl

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)

    height: bookmarksFolderListView.contentHeight

    BookmarksFolderListModel {
        id: bookmarksFolderListModel
        sourceModel: BookmarksModel
    }

    ListView {
        id: bookmarksFolderListView
        objectName: "bookmarksFolderListView"
        anchors.fill: parent
        interactive: false
        focus: true

        model: bookmarksFolderListModel
        delegate: Loader {
            objectName: "bookmarkFolderDelegateLoader"
            anchors {
                left: parent.left
                right: parent.right
            }

            height: active ? item.height : 0
            active: entries.count > 0

            sourceComponent: FocusScope {
                objectName: "bookmarkFolderDelegate"
                focus: true

                function focusHeader() {
                    bookmarkFolderHeader.focus = true
                }
                function focusBookmarks() {
                    bookmarksInFolderLoader.focus = true
                }

                property string folderName: folder

                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                }

                height: childrenRect.height

                property bool expanded: folderName ? false : true

                Item {
                    id: bookmarkFolderHeader
                    objectName: "bookmarkFolderHeader"

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(6.5)
                    focus: true

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2.5)
                            right: parent.right
                        }

                        height: units.gu(6)
                        spacing: units.gu(1.5)

                        Icon {
                            id: expandedIcon
                            name: expanded ? "go-down" : "go-next"

                            height: units.gu(2)
                            width: height

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                                top: parent.top
                            }
                        }

                        Label {
                            width: parent.width - expandedIcon.width - units.gu(3)
                            anchors.verticalCenter: expandedIcon.verticalCenter

                            text: folderName ? folderName : i18n.tr("All Bookmarks")
                            fontSize: "small"
                        }
                    }

                    ListItem.ThinDivider {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            bottomMargin: units.gu(1)
                        }
                    }

                    ListViewHighlight {
                        anchors.fill: parent
                        visible: parent.activeFocus
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: expanded = !expanded
                    }

                    Keys.onEnterPressed: expanded = !expanded
                    Keys.onReturnPressed: expanded = !expanded
                    Keys.onSpacePressed: expanded = !expanded
                }

                Loader {
                    id: bookmarksInFolderLoader
                    anchors {
                        top: bookmarkFolderHeader.bottom
                        left: parent.left
                        right: parent.right
                    }

                    height: item ? item.contentHeight : 0

                    visible: status == Loader.Ready

                    active: expanded
                    onActiveChanged: {
                        if (!active && focus) {
                            focusHeader()
                        }
                    }

                    sourceComponent: ListView {
                        readonly property bool isAllBookmarksFolder: folder === ""

                        focus: true
                        interactive: false
                        currentIndex: 0

                        model: {
                            if (isAllBookmarksFolder) {
                                return BookmarksModelUtils.prependHomepageToBookmarks(entries, {
                                    title: i18n.tr("Homepage"),
                                    url: bookmarksFoldersViewItem.homeBookmarkUrl
                                })
                            }

                            return entries
                        }

                        delegate: UrlDelegate{
                            id: urlDelegate
                            objectName: "urlDelegate_" + index

                            property var entry: isAllBookmarksFolder ? modelData : model

                            width: parent.width
                            height: units.gu(5)

                            removable: !isAllBookmarksFolder || index !== 0

                            icon: entry.icon ? entry.icon : ""
                            title: entry.title ? entry.title : entry.url
                            url: entry.url

                            onClicked: bookmarksFoldersViewItem.bookmarkClicked(url)
                            onRemoved: bookmarksFoldersViewItem.bookmarkRemoved(url)
                        }

                        highlight: ListViewHighlight {}

                        Keys.onUpPressed: {
                            if (currentIndex > 0) {
                                --currentIndex
                            } else {
                                focusHeader()
                            }
                        }
                        Keys.onDownPressed: {
                            if (currentIndex < (count - 1)) {
                                ++currentIndex
                            } else {
                                event.accepted = false
                            }
                        }
                        Keys.onEnterPressed: currentItem.clicked()
                        Keys.onReturnPressed: currentItem.clicked()
                        Keys.onDeletePressed: currentItem.removed()
                    }
                }

                Keys.onDownPressed: {
                    if (expanded && !bookmarksInFolderLoader.focus) {
                        focusBookmarks()
                    } else {
                        event.accepted = false
                    }
                }
            }
        }

        Keys.onUpPressed: {
            var current = currentIndex
            --currentIndex
            while (currentItem && !currentItem.active) {
                --currentIndex
            }
            if (!currentItem) {
                currentIndex = current
            }
        }
        Keys.onDownPressed: {
            var current = currentIndex
            ++currentIndex
            while (currentItem && !currentItem.active) {
                ++currentIndex
            }
            if (!currentItem) {
                currentIndex = current
            }
        }
    }

    // Initially focus the first bookmark
    Component.onCompleted: bookmarksFolderListView.currentItem.item.focusBookmarks()
}
