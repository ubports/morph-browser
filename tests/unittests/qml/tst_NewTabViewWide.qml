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
import QtTest 1.0
import Ubuntu.Test 1.0
import "../../../src/app/webbrowser"
import webbrowserapp.private 0.1

Item {
    id: root

    width: 800
    height: 600

    Component {
        id: historyModel
        HistoryModel {
            databasePath: ":memory:"
        }
    }

    Component {
        id: bookmarksModel
        BookmarksModel {
            databasePath: ":memory:"
        }
    }

    property NewTabViewWide view
    property var bookmarks
    property var history
    property string homepage: "http://example.com/homepage"

    Component {
        id: viewComponent
        NewTabViewWide {
            anchors.fill: parent
            settingsObject: QtObject {
                property url homepage: root.homepage
                property int newTabDefaultSection: 0
            }
            bookmarksModel: bookmarks
            historyModel: history
        }
    }

    SignalSpy {
        id: releasingKeyboardFocusSpy
        signalName: "releasingKeyboardFocus"
    }

    SignalSpy {
        id: historyEntryClickedSpy
        signalName: "historyEntryClicked"
    }

    SignalSpy {
        id: bookmarkClickedSpy
        signalName: "bookmarkClicked"
    }

    SignalSpy {
        id: bookmarkRemovedSpy
        signalName: "bookmarkRemoved"
    }

    UbuntuTestCase {
        name: "NewTabViewWide"
        when: windowShown

        function init() {
            bookmarks = bookmarksModel.createObject()
            history = historyModel.createObject()
            view = viewComponent.createObject(root)
            populate()

            view.focus = true

            releasingKeyboardFocusSpy.target = view
            releasingKeyboardFocusSpy.clear()
            historyEntryClickedSpy.target = view
            historyEntryClickedSpy.clear()
            bookmarkClickedSpy.target = view
            bookmarkClickedSpy.clear()
            bookmarkRemovedSpy.target = view
            bookmarkRemovedSpy.clear()
        }

        function populate() {
            history.add("http://example.com", "Example Com", "")
            history.add("http://example.org", "Example Org", "")
            history.add("http://example.net", "Example Net", "")
            bookmarks.add("http://example.com", "Example Com", "", "")
            bookmarks.add("http://example.org/bar", "Example Org Bar", "", "Folder B")
            bookmarks.add("http://example.org/foo", "Example Org Foo", "", "Folder B")
            bookmarks.add("http://example.net/a", "Example Net A", "", "Folder A")
            bookmarks.add("http://example.net/b", "Example Net B", "", "Folder A")
        }

        function cleanup() {
            history.destroy()
            history = null
            bookmarks.destroy()
            bookmarks = null

            view.destroy()
            view = null
        }

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function getListItems(name, itemName) {
            var list = findChild(view, name)
            var items = []
            if (list) {
                // ensure all the delegates are created
                list.cacheBuffer = list.count * 1000

                // In some cases the ListView might add other children to the
                // contentItem, so we filter the list of children to include
                // only actual delegates
                var children = list.contentItem.children
                for (var i = 0; i < children.length; i++) {
                    if (children[i].objectName === itemName) {
                        items.push(children[i])
                    }
                }
            }
            return items
        }

        function goToBookmarks() {
            findChild(view, "sections").selectedIndex = 1
        }

        function test_topsites_list() {
            // add 8 more top sites so that we are beyond the limit of 10
            for (var i = 0; i < 8; i++) {
                history.add("http://example.com/" + i, "Example Com " + i, "")
            }

            var items = getListItems("topSitesList", "topSiteItem")
            compare(items.length, 10)
            compare(items[0].title, "Example Com")
            compare(items[1].title, "Example Org")
            compare(items[2].title, "Example Net")
            for (var i = 0; i < 7; i++) {
                compare(items[i + 3].title, "Example Com " + i)
            }
        }

        function test_folder_list() {
            var items = getListItems("foldersList", "folderItem")
            compare(items.length, 3)
            verify(items[0].isAllBookmarksFolder)
            compare(items[0].model.folder, "")
            // named folder items should appear alphabetically sorted
            compare(items[1].model.folder, "Folder A")
            compare(items[2].model.folder, "Folder B")
        }

        function test_all_bookmarks_list() {
            var items = getListItems("bookmarksList", "bookmarkItem")
            compare(items.length, 2)
            compare(items[0].url, homepage)
            compare(items[1].title, "Example Com")
        }

        function test_switch_sections_by_keyboard() {
            skip("Would fail due to UITK bug: http://pad.lv/1481233")
            var sections = findChild(view, "sections")
            var folders = findChild(view, "foldersList")
            var bookmarks = findChild(view, "bookmarksList")
            var topSites = findChild(view, "topSitesList")
            compare(sections.selectedIndex, 0)
            verify(topSites.visible)
            verify(!folders.visible)
            verify(!bookmarks.visible)

            keyClick(Qt.Key_Tab)
            compare(sections.selectedIndex, 1)
            verify(!topSites.visible)
            verify(folders.visible)
            verify(bookmarks.visible)

            keyClick(Qt.Key_Backtab)
            compare(sections.selectedIndex, 0)
        }

        function test_navigate_topsites_by_keyboard() {
            var items = getListItems("topSitesList", "topSiteItem")
            findChild(view, "topSitesList").currentIndex = 0
            verify(items[0].highlighted)
            keyClick(Qt.Key_Down)
            verify(!items[0].highlighted)
            verify(items[1].highlighted)
            keyClick(Qt.Key_Down)
            verify(items[2].highlighted)
            keyClick(Qt.Key_Down) // ensure no scrolling past bottom boundary
            verify(items[2].highlighted)
            keyClick(Qt.Key_Up)
            verify(items[1].highlighted)
            keyClick(Qt.Key_Up)
            verify(items[0].highlighted)
            keyClick(Qt.Key_Up)
            verify(items[0].highlighted)
            compare(releasingKeyboardFocusSpy.count, 1)
        }

        function test_activate_topsites_by_keyboard() {
            var items = getListItems("topSitesList", "topSiteItem")
            keyClick(Qt.Key_Return)
            compare(historyEntryClickedSpy.count, 1)
            compare(historyEntryClickedSpy.signalArguments[0][0], "http://example.com")
            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            compare(historyEntryClickedSpy.count, 2)
            compare(historyEntryClickedSpy.signalArguments[1][0], "http://example.org")
        }

        function test_navigate_folders_by_keyboard() {
            goToBookmarks()

            var foldersList = getListItems(view, "foldersList")
            var folders = getListItems("foldersList", "folderItem")
            verify(folders[0].isActiveFolder)

            keyClick(Qt.Key_Down)
            verify(!folders[0].isActiveFolder)
            verify(folders[1].isActiveFolder)

            // bookmarks within a folder are sorted with the first bookmarked appearing last
            var items = getListItems("bookmarksList", "bookmarkItem")
            compare(items[0].title, "Example Net B")
            compare(items[1].title, "Example Net A")
            compare(items.length, 2)

            keyClick(Qt.Key_Down)
            verify(folders[2].isActiveFolder)
            items = getListItems("bookmarksList", "bookmarkItem")
            compare(items[0].title, "Example Org Foo")
            compare(items[1].title, "Example Org Bar")
            compare(items.length, 2)

            // verify scrolling beyond bottom of list is not allowed
            keyClick(Qt.Key_Down)
            verify(folders[2].isActiveFolder)

            keyClick(Qt.Key_Up)
            verify(folders[1].isActiveFolder)
            keyClick(Qt.Key_Up)
            verify(folders[0].isActiveFolder)

            keyClick(Qt.Key_Up)
            compare(releasingKeyboardFocusSpy.count, 1)
        }

        function test_switch_between_folder_and_bookmarks_by_keyboard() {
            goToBookmarks()

            var folders = findChild(view, "foldersList")
            var bookmarks = findChild(view, "bookmarksList")

            keyClick(Qt.Key_Right)
            verify(bookmarks.activeFocus)
            keyClick(Qt.Key_Right)
            verify(bookmarks.activeFocus) // verify no circular scrolling

            keyClick(Qt.Key_Left)
            verify(folders.activeFocus)
            keyClick(Qt.Key_Left)
            verify(folders.activeFocus) // verify no circular scrolling
        }

        function test_activate_bookmarks_by_keyboard() {
            goToBookmarks()
            keyClick(Qt.Key_Right)

            var items = getListItems("bookmarksList", "bookmarkItem")
            keyClick(Qt.Key_Return)
            compare(bookmarkClickedSpy.count, 1)
            compare(bookmarkClickedSpy.signalArguments[0][0], homepage)

            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            compare(bookmarkClickedSpy.count, 2)
            compare(bookmarkClickedSpy.signalArguments[1][0], "http://example.com")
        }

        function test_activate_topsites_by_mouse() {
            var items = getListItems("topSitesList", "topSiteItem")
            clickItem(items[0])
            compare(historyEntryClickedSpy.count, 1)
            compare(historyEntryClickedSpy.signalArguments[0][0], "http://example.com")

            clickItem(items[1])
            compare(historyEntryClickedSpy.count, 2)
            compare(historyEntryClickedSpy.signalArguments[1][0], "http://example.org")

        }

        function test_activate_bookmarks_by_mouse() {
            goToBookmarks()
            var items = getListItems("bookmarksList", "bookmarkItem")
            clickItem(items[0])
            compare(bookmarkClickedSpy.count, 1)
            compare(bookmarkClickedSpy.signalArguments[0][0], homepage)

            clickItem(items[1])
            compare(bookmarkClickedSpy.count, 2)
            compare(bookmarkClickedSpy.signalArguments[1][0], "http://example.com")
        }

        function test_switch_folders_by_mouse() {
            goToBookmarks()
            var folders = getListItems("foldersList", "folderItem")

            clickItem(folders[1])
            var items = getListItems("bookmarksList", "bookmarkItem")
            compare(items[0].title, "Example Net B")
            compare(items[1].title, "Example Net A")
            compare(items.length, 2)

            clickItem(folders[0])
            items = getListItems("bookmarksList", "bookmarkItem")
            compare(items[0].url, homepage)
            compare(items[1].title, "Example Com")
            compare(items.length, 2)
        }

        function test_remove_bookmarks_by_keyboard() {
            goToBookmarks()
            keyClick(Qt.Key_Right)
            var items = getListItems("bookmarksList", "bookmarkItem")

            // verify that trying to delete the homepage bookmark does not work
            keyClick(Qt.Key_Delete)
            compare(bookmarkRemovedSpy.count, 0)

            keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Delete)
            compare(bookmarkRemovedSpy.count, 1)
            compare(bookmarkRemovedSpy.signalArguments[0][0], items[1].url)
        }

        function test_remove_top_sites_by_keyboard() {
            var previous = getListItems("topSitesList", "topSiteItem")
            keyClick(Qt.Key_Delete)
            var items = getListItems("topSitesList", "topSiteItem")
            compare(previous.length - 1, items.length)
        }
    }
}
