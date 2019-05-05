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
import ".." as Common
import "." as Local

Common.BrowserPage {
    id: bookmarksView

    property alias homepageUrl: bookmarksFoldersView.homeBookmarkUrl

    signal bookmarkEntryClicked(url url)
    signal newTabClicked()

    title: i18n.tr("Bookmarks")

    BookmarksFoldersView {
        id: bookmarksFoldersView

        anchors {
            top: parent.top
            bottom: toolbar.top
            left: parent.left
            right: parent.right
        }

        interactive: true
        focus: true

        onBookmarkClicked: bookmarksView.bookmarkEntryClicked(url)
        onBookmarkRemoved: {
            if (BookmarksModel.count == 1) {
                bookmarksView.back()
            }
            BookmarksModel.remove(url)
        }
    }

    Local.Toolbar {
        id: toolbar
        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            activeFocusOnPress: false
            strokeColor: theme.palette.selected.base
            text: i18n.tr("Done")

            onClicked: bookmarksView.back()
        }

        ToolbarAction {
            objectName: "newTabAction"
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: bookmarksView.newTabClicked()
        }
    }
}
