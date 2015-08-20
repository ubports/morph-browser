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
import QtTest 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Test 1.0
import "../../../src/app/webbrowser"

Item {
    id: root

    width: 700
    height: 500

    HistoryViewWide {
        id: historyViewWide
        anchors.fill: parent
        historyModel: HistoryModel {
            id: historyMockModel
            databasePath: ":memory:"
        }
    }

    SignalSpy {
        id: doneSpy
        target: historyViewWide
        signalName: "done"
    }

    SignalSpy {
        id: newTabRequestedSpy
        target: historyViewWide
        signalName: "newTabRequested"
    }

    SignalSpy {
        id: historyEntryClickedSpy
        target: historyViewWide
        signalName: "historyEntryClicked"
    }

    SignalSpy {
        id: historyEntryRemovedSpy
        target: historyViewWide
        signalName: "historyEntryRemoved"
    }

    UbuntuTestCase {
        name: "HistoryViewWide"
        when: windowShown

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function longPressItem(item) {
            var center = centerOf(item)
            mousePress(item, center.x, center.y)
            mouseRelease(item, center.x, center.y, Qt.LeftButton, Qt.NoModifier, 2000)
        }

        function swipeItemRight(item) {
            var center = centerOf(item)
            mousePress(item, center.x, center.y)
            mouseRelease(item, center.x + 100, center.y, Qt.LeftButton, Qt.NoModifier, 2000)
        }

        function initTestCase() {
            for (var i = 0; i < 3; ++i) {
                historyMockModel.add("http://example.org/" + i, "Example Domain " + i, "")
            }
            var urlsList = findChild(historyViewWide, "urlsListView")
            waitForRendering(urlsList)
            tryCompare(urlsList, "count", 3)
        }

        function test_done_button() {
            var doneButton = findChild(historyViewWide, "doneButton")
            verify(doneButton != null)
            doneSpy.clear()
            compare(doneSpy.count, 0)
            clickItem(doneButton)
            compare(doneSpy.count, 1)
        }

        function test_new_tab_button() {
            var newTabButton = findChild(historyViewWide, "newTabButton")
            verify(newTabButton != null)
            doneSpy.clear()
            newTabRequestedSpy.clear()
            compare(doneSpy.count, 0)
            compare(newTabRequestedSpy.count, 0)
            clickItem(newTabButton)
            compare(newTabRequestedSpy.count, 1)
            compare(doneSpy.count, 1)
        }

        function test_history_entry_clicked() {
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 3)
            compare(historyEntryClickedSpy.count, 0)
            clickItem(urlsList.children[0])
            compare(historyEntryClickedSpy.count, 1)
            var args = historyEntryClickedSpy.signalArguments[0]
            var entry = urlsList.model.get(0)
            compare(args[0], entry.url)
        }

        function test_selection_mode() {
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 3)
            var backButton = findChild(historyViewWide, "backButton")
            var selectButton = findChild(historyViewWide, "selectButton")
            var deleteButton = findChild(historyViewWide, "deleteButton")
            verify(!backButton.visible)
            verify(!selectButton.visible)
            verify(!deleteButton.visible)
            longPressItem(urlsList.children[0])
            verify(backButton.visible)
            verify(selectButton.visible)
            verify(deleteButton.visible)
            clickItem(backButton)
            verify(!backButton.visible)
            verify(!selectButton.visible)
            verify(!deleteButton.visible)
        }

        function test_toggle_select_button() {
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 3)
            longPressItem(urlsList.children[0])
            var selectedIndices = urlsList.ViewItems.selectedIndices
            compare(selectedIndices.length, 1)
            var selectButton = findChild(historyViewWide, "selectButton")
            clickItem(selectButton)
            compare(selectedIndices.length, urlsList.count)
            clickItem(selectButton)
            var backButton = findChild(historyViewWide, "backButton")
            clickItem(backButton)
        }

        function test_delete_button() {
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 3)
            longPressItem(urlsList.children[0])
            var deleteButton = findChild(historyViewWide, "deleteButton")
            compare(historyEntryRemovedSpy.count, 0)
            clickItem(deleteButton)
            compare(historyEntryRemovedSpy.count, 1)
            var args = historyEntryRemovedSpy.signalArguments[0]
            var entry = urlsList.model.get(0)
            compare(args[0], entry.url)
        }

        function test_keyboard_navigation_between_lists() {
            var lastVisitDateList = findChild(historyViewWide, "lastVisitDateListView")
            var urlsList = findChild(historyViewWide, "urlsListView")
            verify(!lastVisitDateList.activeFocus)
            keyClick(Qt.Key_Left)
            verify(lastVisitDateList.activeFocus)
            verify(!urlsList.activeFocus)
            keyClick(Qt.Key_Right)
            verify(urlsList.activeFocus)
        }

        function test_search_button() {
            var searchButton = findChild(historyViewWide, "searchButton")
            verify(searchButton.visible)
            clickItem(searchButton)
            verify(!searchButton.visible)

            var searchQuery = findChild(historyViewWide, "searchQuery")
            verify(searchQuery.visible)
            verify(searchQuery.activeFocus)
            compare(searchQuery.text, "")

            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 3)
            typeString("2")
            compare(urlsList.count, 1)

            var backButton = findChild(historyViewWide, "backButton")
            verify(backButton.visible)
            clickItem(backButton)
            verify(!backButton.visible)
            verify(!searchQuery.visible)
            verify(searchButton.visible)
            compare(urlsList.count, 3)

            clickItem(searchButton)
            compare(searchQuery.text, "")
        }
    }
}
