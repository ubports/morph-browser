/*
 * Copyright 2016 Canonical Ltd.
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
import QtQuick.Window 2.2
import QtTest 1.0
import Qt.labs.settings 1.0
import "../../../src/app/webbrowser"
import webbrowserapp.private 0.1

FocusScope {
    id: root

    focus: true
    width: 350
    height: 500

    Loader {
        id: newTabViewLoader
        anchors.fill: parent
        focus: true
        active: false
        sourceComponent: NewTabView {
            focus: true
            anchors.fill: parent
            settingsObject: Settings {
                property url homepage: "http://example.com/homepage"
            }
        }
    }

    readonly property Item view: newTabViewLoader.item

    SignalSpy {
        id: bookmarkClickedSpy
        target: view
        signalName: "bookmarkClicked"
    }

    SignalSpy {
        id: bookmarkRemovedSpy
        target: view
        signalName: "bookmarkRemoved"
    }

    SignalSpy {
        id: historyEntryClickedSpy
        target: view
        signalName: "historyEntryClicked"
    }

    SignalSpy {
        id: countChangedSpy
        signalName: "countChanged"
    }

    WebbrowserTestCase {
        name: "NewTabView"
        when: windowShown

        function init() {
            HistoryModel.databasePath = ":memory:"
            BookmarksModel.databasePath = ":memory:"
            populate()
            newTabViewLoader.active = true
            waitForRendering(view)
            verify(view.activeFocus)
            compare(bookmarkClickedSpy.count, 0)
            compare(bookmarkRemovedSpy.count, 0)
            compare(historyEntryClickedSpy.count, 0)
        }

        function populate() {
            HistoryModel.add("http://example.com/foo", "foo", "")
            HistoryModel.add("http://example.org/bar", "bar", "")
            HistoryModel.add("http://example.net/baz", "baz", "")
            HistoryModel.add("http://example.net/qux", "qux", "")
            HistoryModel.add("http://example.net/norf", "norf", "")
            compare(HistoryModel.count, 5)

            BookmarksModel.add("http://example.com", "Example", "", "")
            BookmarksModel.add("http://example.org/a", "Example a", "", "FolderA")
            BookmarksModel.add("http://example.org/b", "Example b", "", "FolderB")
            BookmarksModel.add("http://example.org/c", "Example c", "", "FolderC")
            BookmarksModel.add("http://example.org/d", "Example d", "", "FolderD")
            compare(BookmarksModel.count, 5)
        }

        function cleanup() {
            newTabViewLoader.active = false
            BookmarksModel.databasePath = ""
            HistoryModel.databasePath = ""
            bookmarkClickedSpy.clear()
            bookmarkRemovedSpy.clear()
            historyEntryClickedSpy.clear()
        }

        function verify_bookmarks_expanded(expected) {
            if (expected) {
                compare(findChild(view, "bookmarksList"), null)
                compare(findChild(view, "bookmarksFolderListView").objectName,
                        "bookmarksFolderListView")
            } else {
                compare(findChild(view, "bookmarksList").objectName,
                        "bookmarksList")
                compare(findChild(view, "bookmarksFolderListView"), null)
            }
        }

        function check_focused_item(objectName) {
            var focused = root.Window.activeFocusItem
            verify(focused !== null)
            compare(focused.objectName, objectName)
            return focused
        }

        function test_click_bookmark() {
            var listview = findChild(view, "bookmarksList")

            var homepage = findChild(listview, "homepageBookmark")
            clickItem(homepage)
            compare(bookmarkClickedSpy.count, 1)
            compare(bookmarkClickedSpy.signalArguments[0][0],
                    view.settingsObject.homepage)

            var bookmark = findChild(listview, "bookmark_1")
            clickItem(bookmark)
            compare(bookmarkClickedSpy.count, 2)
            compare(bookmarkClickedSpy.signalArguments[1][0], bookmark.url)
        }

        function test_delete_bookmark() {
            var listview = findChild(view, "bookmarksList")
            var bookmark = findChild(listview, "bookmark_2")
            swipeToDeleteAndConfirm(bookmark)
            bookmarkRemovedSpy.wait()
            compare(bookmarkRemovedSpy.count, 1)
            compare(bookmarkRemovedSpy.signalArguments[0][0], bookmark.url)
        }

        function test_expand_bookmarks() {
            verify_bookmarks_expanded(false)
            var button = findChild(view, "bookmarks.moreButton")
            clickItem(button)
            verify_bookmarks_expanded(true)
            clickItem(button)
            verify_bookmarks_expanded(false)
        }

        function test_click_top_site() {
            var grid = findChild(view, "topSitesList")
            compare(grid.count, 5)
            var topsites = getListItems(grid, "topSiteItem")
            compare(topsites.length, 5)
            var topsite = topsites[3]
            clickItem(topsite)
            compare(historyEntryClickedSpy.count, 1)
            compare(historyEntryClickedSpy.signalArguments[0][0], topsite.url)
        }

        function test_delete_top_site() {
            var grid = findChild(view, "topSitesList")
            compare(grid.count, 5)
            var topsite = getListItems(grid, "topSiteItem")[1]
            clickItem(topsite, Qt.RightButton)
            var contextMenu = findChild(root, "urlPreviewDelegate.contextMenu")
            var action = findChild(contextMenu, "delete_button")
            clickItem(action)
            compare(grid.count, 4)
        }

        function test_keyboard_navigation() {
            var bookmarksList = findChild(view, "bookmarksList")
            verify(bookmarksList.activeFocus)
            check_focused_item("homepageBookmark")

            keyClick(Qt.Key_Up)
            check_focused_item("bookmarkListHeader")

            verify_bookmarks_expanded(false)
            keyClick(Qt.Key_Enter)
            verify_bookmarks_expanded(true)
            keyClick(Qt.Key_Return)
            verify_bookmarks_expanded(false)
            keyClick(Qt.Key_Space)
            verify_bookmarks_expanded(true)
            keyClick(Qt.Key_Enter)
            verify_bookmarks_expanded(false)

            keyClick(Qt.Key_Up)
            check_focused_item("bookmarkListHeader")

            keyClick(Qt.Key_Down)
            check_focused_item("homepageBookmark")

            keyClick(Qt.Key_Delete)
            compare(bookmarkRemovedSpy.count, 0)

            keyClick(Qt.Key_Enter)
            compare(bookmarkClickedSpy.count, 1)
            compare(bookmarkClickedSpy.signalArguments[0][0],
                    view.settingsObject.homepage)

            keyClick(Qt.Key_Down)
            var bookmark = check_focused_item("bookmark_1")

            keyClick(Qt.Key_Delete)
            compare(bookmarkRemovedSpy.count, 1)
            compare(bookmarkRemovedSpy.signalArguments[0][0], bookmark.url)

            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Down)
            check_focused_item("bookmark_4")

            keyClick(Qt.Key_Down)
            var grid = findChild(view, "topSitesList")
            verify(grid.activeFocus)
            compare(grid.currentIndex, 0)
            var topsite = check_focused_item("topSiteItem")

            keyClick(Qt.Key_Enter)
            compare(historyEntryClickedSpy.count, 1)
            compare(historyEntryClickedSpy.signalArguments[0][0], topsite.url)

            keyClick(Qt.Key_Return)
            compare(historyEntryClickedSpy.count, 2)
            compare(historyEntryClickedSpy.signalArguments[1][0], topsite.url)

            keyClick(Qt.Key_Right)
            compare(grid.currentIndex, 1)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Down)
            compare(grid.currentIndex, 3)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Down)
            compare(grid.currentIndex, 3)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Left)
            compare(grid.currentIndex, 2)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Down)
            compare(grid.currentIndex, 4)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Down)
            compare(grid.currentIndex, 4)
            check_focused_item("topSiteItem")

            keyClick(Qt.Key_Left)
            compare(grid.currentIndex, 3)
            check_focused_item("topSiteItem")

            var notopsiteslabel = findChild(view, "notopsites")
            verify(!notopsiteslabel.visible)
            compare(grid.count, 5)
            countChangedSpy.target = grid
            for (var i = 4; i >= 0; --i) {
                keyClick(Qt.Key_Delete)
                countChangedSpy.wait()
                compare(grid.count, i)
                compare(grid.currentIndex, i - 1)
            }
            compare(grid.count, 0)
            verify(notopsiteslabel.visible)
            bookmarksList = findChild(view, "bookmarksList")
            verify(bookmarksList.activeFocus)

            keyClick(Qt.Key_Down)
            verify(bookmarksList.activeFocus)
        }
    }
}
