/*
 * Copyright 2014-2016 Canonical Ltd.
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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import webbrowserapp.private 0.1
import "."

FocusScope {
    id: newTabView

    property Settings settingsObject

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)

    TopSitesModel {
        id: topSitesModel
        model: HistoryModel
    }

    QtObject {
        id: internal

        property bool seeMoreBookmarksView: false
        property int bookmarksCountLimit: Math.min(4, numberOfBookmarks)
        property int numberOfBookmarks: BookmarksModel.count

        // Force the topsites section to reappear when remove a bookmark while
        // the bookmarks list is expanded and there aren't anymore > 5
        // bookmarks
        onNumberOfBookmarksChanged: {
            if (numberOfBookmarks <= 4) {
                seeMoreBookmarksView = false
            }
        }

        function ensureCurrentItemVisible(container, currentItem) {
            if (container.activeFocus && currentItem) {
                var top = container.y + currentItem.mapToItem(container, 0, 0).y
                var height = currentItem.height
                if (top < flickable.contentY) {
                    flickable.contentY = top
                } else if ((flickable.contentY + flickable.height) < (top + height)) {
                    flickable.contentY = top + height - flickable.height
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.foreground
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentScope.height

        Behavior on contentY {
            UbuntuNumberAnimation {}
        }

        FocusScope {
            id: contentScope
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height

            focus: true

            Item {
                id: bookmarkListHeader
                objectName: "bookmarkListHeader"
                height: units.gu(6)
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                Row {
                    anchors {
                        fill: parent
                        leftMargin: units.gu(2)
                        rightMargin: units.gu(2)
                    }
                    spacing: units.gu(1.5)

                    Icon {
                        id: starredIcon
                        color: "#dd4814"
                        name: "starred"

                        height: units.gu(2)
                        width: height

                        anchors {
                            leftMargin: units.gu(1)
                            topMargin: units.gu(1)
                            verticalCenter: moreButton.verticalCenter
                        }
                    }

                    Label {
                        width: parent.width - starredIcon.width - moreButton.width - units.gu(3)
                        anchors.verticalCenter: moreButton.verticalCenter

                        text: i18n.tr("Bookmarks")
                        fontSize: "small"
                    }

                    Button {
                        id: moreButton
                        objectName: "bookmarks.moreButton"
                        height: parent.height - units.gu(2)
                        anchors { top: parent.top; topMargin: units.gu(1) }
                        activeFocusOnPress: false

                        strokeColor: theme.palette.selected.base
                        visible: internal.numberOfBookmarks > 4
                        text: internal.seeMoreBookmarksView ? i18n.tr("Less") : i18n.tr("More")

                        onClicked: {
                            internal.seeMoreBookmarksView = !internal.seeMoreBookmarksView
                            bookmarkListHeader.focus = true
                        }
                    }
                }

                Keys.onEnterPressed: moreButton.clicked()
                Keys.onReturnPressed: moreButton.clicked()
                Keys.onSpacePressed: moreButton.clicked()

                Keys.onDownPressed: {
                    if (internal.seeMoreBookmarksView) {
                        bookmarksFolderListViewLoader.focus = true
                    } else {
                        bookmarkList.focus = true
                    }
                }

                onActiveFocusChanged: internal.ensureCurrentItemVisible(this, this)
            }

            ListViewHighlight {
                anchors.fill: bookmarkListHeader
                visible: hasKeyboard && bookmarkListHeader.activeFocus
            }

            ListItems.ThinDivider {
                id: bookmarkListDivider
                anchors {
                    top: bookmarkListHeader.bottom
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                opacity: bookmarkListHeader.activeFocus ? 0 : 1
            }

            Loader {
                id: bookmarksFolderListViewLoader
                anchors {
                    top: bookmarkListDivider.bottom
                    left: parent.left
                    right: parent.right
                }
                active: internal.seeMoreBookmarksView
                height: active ? item.height : 0

                sourceComponent: BookmarksFoldersView {
                    focus: true
                    interactive: false

                    homeBookmarkUrl: newTabView.settingsObject.homepage

                    onBookmarkClicked: newTabView.bookmarkClicked(url)
                    onBookmarkRemoved: newTabView.bookmarkRemoved(url)

                    onCurrentItemChanged: internal.ensureCurrentItemVisible(bookmarksFolderListViewLoader, currentItem)
                    onActiveFocusChanged: internal.ensureCurrentItemVisible(bookmarksFolderListViewLoader, currentItem)
                }

                Keys.onUpPressed: {
                    if (moreButton.visible) {
                        bookmarkListHeader.focus = true
                    } else {
                        event.accepted = false
                    }
                }
            }

            Loader {
                id: bookmarkList
                anchors {
                    top: bookmarkListDivider.bottom
                    left: parent.left
                    right: parent.right
                }
                active: !internal.seeMoreBookmarksView
                height: active ? item.height : 0
                focus: true

                LimitProxyModel {
                    id: limitedBookmarksModel
                    sourceModel: BookmarksModel
                    limit: internal.bookmarksCountLimit
                }

                sourceComponent: ListView {
                    objectName: "bookmarksList"
                    focus: true
                    interactive: false
                    readonly property real delegateHeight: units.gu(5)
                    height: (newTabView.settingsObject.homepage.toString() === "") ? ((count - 1) * delegateHeight) : (count * delegateHeight)

                    model: limitedBookmarksModel.count + 1

                    delegate: UrlDelegate {
                        objectName: (index == 0) ? "homepageBookmark" : "bookmark_%1".arg(index)
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        height: visible ? delegateHeight : 0
                        removable: index > 0

                        readonly property var data: BookmarksModel.count ? limitedBookmarksModel.get(index - 1) : null
                        icon: (index > 0) ? data.icon : ""
                        title: (index > 0) ? data.title : i18n.tr("Homepage")
                        url: (index > 0) ? data.url : newTabView.settingsObject.homepage
                        visible: (index > 0) ? true : (newTabView.settingsObject.homepage.toString() !== "")

                        onClicked: newTabView.bookmarkClicked(url)
                        onRemoved: {
                            if (removable) {
                                newTabView.bookmarkRemoved(url)
                            }
                        }
                    }

                    Keys.onDeletePressed: currentItem.removed()

                    // Setting 'interactive' to false to prevent flicks also disables
                    // keyboard navigation, so it needs to be manually implemented.
                    Keys.onUpPressed: {
                        var current = currentIndex
                        decrementCurrentIndex()
                        if (currentIndex == current) {
                            event.accepted = false
                        }
                    }
                    Keys.onDownPressed: {
                        var current = currentIndex
                        incrementCurrentIndex()
                        if (currentIndex == current) {
                            event.accepted = false
                        }
                    }

                    onCurrentItemChanged: internal.ensureCurrentItemVisible(bookmarkList, currentItem)
                    onActiveFocusChanged: internal.ensureCurrentItemVisible(bookmarkList, currentItem)
                }

                Keys.onUpPressed: {
                    if (moreButton.visible) {
                        bookmarkListHeader.focus = true
                    } else {
                        event.accepted = false
                    }
                }
                Keys.onDownPressed: {
                    if (topSitesGrid.visible) {
                        topSitesGrid.focus = true
                    } else {
                        event.accepted = false
                    }
                }
            }

            Item {
                id: topSitesHeader
                anchors {
                    top: bookmarkList.bottom
                    left: parent.left
                    right: parent.right
                }
                visible: !internal.seeMoreBookmarksView
                height: visible ? units.gu(6) : 0

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                        bottom: parent.bottom
                        bottomMargin: units.gu(1)
                    }

                    opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                    Behavior on opacity { UbuntuNumberAnimation {} }

                    text: i18n.tr("Top sites")
                    fontSize: "small"
                }
            }

            ListItems.ThinDivider {
                id: topSitesDivider
                anchors {
                    top: topSitesHeader.bottom
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                }
                visible: topSitesHeader.visible
            }

            Label {
                objectName: "notopsites"

                anchors {
                    top: topSitesDivider.bottom
                    left: parent.left
                    right: parent.right
                }
                visible: !internal.seeMoreBookmarksView && (topSitesModel.count == 0)
                height: visible ? units.gu(11) : 0

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: i18n.tr("You haven't visited any site yet")
                color: theme.palette.selected.base
            }

            FocusScope {
                id: topSitesGrid
                anchors {
                    top: topSitesDivider.bottom
                    left: parent.left
                    right: parent.right
                }
                visible: !internal.seeMoreBookmarksView && (topSitesModel.count > 0)
                height: visible ? grid.contentHeight + units.gu(1) : 0
                clip: true

                UrlPreviewGrid {
                    id: grid
                    objectName: "topSitesList"
                    focus: true
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        right: parent.right
                        rightMargin: units.gu(2)
                        top: parent.top
                        topMargin: units.gu(2)
                        bottom: parent.bottom
                    }

                    horizontalMargin: units.gu(1)
                    verticalMargin: units.gu(1)

                    opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                    Behavior on opacity { UbuntuNumberAnimation {} }
                    visible: opacity > 0
                    interactive: false

                    model: LimitProxyModel {
                        limit: 10
                        sourceModel: topSitesModel
                    }
                    showFavicons: false

                    onActivated: newTabView.historyEntryClicked(url)
                    onRemoved: {
                        HistoryModel.hide(url)
                        PreviewManager.checkDelete(url)
                    }

                    // Setting 'interactive' to false to prevent flicks also disables
                    // keyboard navigation, so it needs to be manually implemented.
                    Keys.onLeftPressed: moveCurrentIndexLeft()
                    Keys.onRightPressed: moveCurrentIndexRight()

                    onCurrentItemChanged: internal.ensureCurrentItemVisible(topSitesGrid, currentItem)
                    onActiveFocusChanged: internal.ensureCurrentItemVisible(topSitesGrid, currentItem)

                    onCountChanged: {
                        if (activeFocus && (count == 0)) {
                            bookmarkList.focus = true
                        }
                    }
                }

                Keys.onUpPressed: bookmarkList.focus = true
            }
        }
    }
}
