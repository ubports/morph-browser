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
import Ubuntu.Components 1.2
import Ubuntu.Test 1.0
import "../../../src/app/webbrowser"

Item {
    id: root

    width: 700
    height: 500

    HistoryViewWide {
        id: historyViewWide
        
        property bool populatedModel: false

        anchors.fill: parent

        historyModel: HistoryModel {
            id: historyModel
        }

        Timer {
            id: populateTimer

            property int count: 0

            interval: 1001
            repeat: true
            onTriggered: {
                if (count == 4) {
                    historyViewWide.populatedModel = true
                    stop()
                }
                historyModel.add("http://example.org/" + count, "URL " + count, "")
                count++
            }
        }

        Component.onCompleted: populateTimer.start()
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

    UbuntuTestCase {
        name: "HistoryViewWide"
        when: historyViewWide.populatedModel

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function longPressItem(item) {
            var center = centerOf(item)
            mousePress(item, center.x, center.y)
            mouseRelease(item, center.x, center.y, Qt.LeftButton, Qt.NoModifier, 2000)
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

        function test_urls_list_click() {
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 5)
            var entry = urlsList.children[0]
            historyEntryClickedSpy.clear()
            compare(historyEntryClickedSpy.count, 0)
            clickItem(entry)
            compare(historyEntryClickedSpy.count, 1)
        }

        function test_urls_list_long_press() {
            var backButton = findChild(historyViewWide, "backButton")
            var selectButton = findChild(historyViewWide, "selectButton")
            var deleteButton = findChild(historyViewWide, "deleteButton")
            var urlsList = findChild(historyViewWide, "urlsListView")
            compare(urlsList.count, 5)
            verify(!backButton.visible)
            verify(!selectButton.visible)
            verify(!deleteButton.visible)
            var entry = urlsList.children[0]
            longPressItem(entry)
            verify(backButton.visible)
            verify(selectButton.visible)
            verify(deleteButton.visible)
        }
    }
}
