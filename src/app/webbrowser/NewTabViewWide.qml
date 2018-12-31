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
import "."

FocusScope {
    id: newTabViewWide

    property QtObject settingsObject
    property alias selectedIndex: sections.selectedIndex
    readonly property bool inBookmarksView: newTabViewWide.selectedIndex === 1

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)

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
            model: HistoryModel
        }
    }

    BookmarksFoldersViewWide {
        id: bookmarksFoldersViewWide

        onBookmarkClicked: newTabViewWide.bookmarkClicked(url)
        onBookmarkRemoved: newTabViewWide.bookmarkRemoved(url)

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
        color: theme.palette.normal.foreground
    }

    UrlPreviewGrid {
        id: topSitesList
        objectName: "topSitesList"
        anchors {
            top: sectionsGroup.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: units.gu(3)
            leftMargin: units.gu(4)
        }

        visible: !inBookmarksView

        model: topSitesModel
        showFavicons: true

        onActivated: newTabViewWide.historyEntryClicked(url)
        onRemoved: {
            HistoryModel.hide(url)
            PreviewManager.checkDelete(url)
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
        color: theme.palette.normal.background
        height: sections.height

        Sections {
            id: sections
            objectName: "sections"
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: units.gu(2)
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

        Rectangle {
            // Divider, see Ubuntu/Components/Themes/Ambiance/1.3/PageHeaderStyle.qml
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
            }
            height: units.dp(1)
            color: Qt.rgba(0, 0, 0, 0.1)
        }
    }
}
