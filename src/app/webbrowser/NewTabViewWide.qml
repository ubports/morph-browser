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

    property alias bookmarksModel: bookmarksFoldersViewWide.model
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
                bookmarksFoldersViewWide.restoreLastFocusedColumn()
            } else {
                topSitesList.focus = true
            }
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

    BookmarksFoldersViewWide {
        id: bookmarksFoldersViewWide

        Keys.onUpPressed: newTabViewWide.releasingKeyboardFocus()
        onBookmarkClicked: newTabViewWide.bookmarkClicked(url)
        onBookmarkRemoved: newTabViewWide.bookmarkRemoved(url)
 
        // Relinquish focus as the presses and releases that compose the
        // drag will move the keyboard focus in a location unexpected
        // for the user. This way it will go back to the address bar and
        // the user can predictably resume keyboard interaction from there.
        onDragStarted: newTabViewWide.releasingKeyboardFocus()
 
        anchors {
            top: sectionsGroup.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        visible: inBookmarksView
        homeBookmarkUrl: newTabViewWide.settingsObject.homepage
    }

    Rectangle {
        anchors.fill: parent
        visible: !inBookmarksView
        color: "#fbfbfb"
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
        delegate: UrlDelegateWide {
            objectName: "topSiteItem"
            clip: true

            title: model.title
            icon: model.icon
            url: model.url
            highlighted: topSitesList.activeFocus && ListView.isCurrentItem

            onClicked: newTabViewWide.historyEntryClicked(url)
            onRemoved: newTabViewWide.historyModel.hide(url)
        }

        Keys.onReturnPressed: newTabViewWide.historyEntryClicked(currentItem.url)
        Keys.onDeletePressed: {
            newTabViewWide.historyModel.hide(currentItem.url)
            if (topSitesList.model.count === 0) newTabViewWide.releasingKeyboardFocus()
        }
        Keys.onDownPressed: currentIndex = Math.min(currentIndex + 1, model.count - 1)
        Keys.onUpPressed: {
            if (currentIndex > 0) currentIndex = Math.max(currentIndex - 1, 0)
            else newTabViewWide.releasingKeyboardFocus()
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
                if (selectedIndex === 0) {
                    topSitesList.focus = true
                } else {
                    bookmarksFoldersViewWide.restoreLastFocusedColumn()
                }
            }

            actions: [
                Action { text: i18n.tr("Top sites") },
                Action { text: i18n.tr("Bookmarks") }
            ]
        }
    }
}
