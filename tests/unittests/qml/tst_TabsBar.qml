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

Item {
    width: 600
    height: 50

    ListModel {
        id: tabsModel
        property int currentIndex: -1
    }

    TabsBar {
        id: tabs
        anchors.fill: parent
        model: tabsModel
        onRequestNewTab: appendTab("", "", "")
        function appendTab(url, title, icon) {
            model.append({"url": url, "title": title, "icon": icon})
            model.currentIndex = model.count - 1
        }
    }

    SignalSpy {
        id: newTabRequestSpy
        target: tabs
        signalName: "requestNewTab"
    }

    UbuntuTestCase {
        name: "TabsBar"
        when: windowShown

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function getTabDelegate(index) {
            return findChild(tabs, "tabDelegate_" + index)
        }

        function cleanup() {
            tabsModel.clear()
            newTabRequestSpy.clear()
        }

        function test_create_new_tab() {
            var newTabButton = findChild(tabs, "newTabButton")
            for (var i = 0; i < 3; ++i) {
                tryCompare(tabsModel, "count", i)
                clickItem(newTabButton)
            }
            compare(newTabRequestSpy.count, 3)
        }

        function test_mouse_left_click() {
            // Left click makes the tab current
            tabs.appendTab()
            tabs.appendTab()
            tabs.appendTab()
            compare(tabsModel.currentIndex, 2)
            for (var i = 2; i >= 0; --i) {
                clickItem(getTabDelegate(i))
                compare(tabsModel.currentIndex, i)
            }
        }

        function test_mouse_middle_click() {
            // Middle click closes the tab
            tabs.appendTab()
            tabs.appendTab()
            tabs.appendTab()
            compare(tabsModel.currentIndex, 2)
            for (var i = 2; i >= 0; --i) {
                var tab0 = getTabDelegate(0)
                mouseClick(tab0, centerOf(tab0).x, centerOf(tab0).y, Qt.MiddleButton)
                compare(tabsModel.count, i)
            }
        }

        function test_mouse_wheel() {
            // Wheel events cycle through open tabs
            tabs.appendTab()
            tabs.appendTab()
            tabs.appendTab()
            compare(tabsModel.currentIndex, 2)
            var tab0 = getTabDelegate(0)
            var c = centerOf(tab0)
            function wheelUp() { mouseWheel(tab0, c.x, c.y, 0, 120) }
            function wheelDown() { mouseWheel(tab0, c.x, c.y, 0, -120) }
            wheelDown()
            compare(tabsModel.currentIndex, 2)
            wheelUp()
            compare(tabsModel.currentIndex, 1)
            wheelUp()
            compare(tabsModel.currentIndex, 0)
            wheelUp()
            compare(tabsModel.currentIndex, 0)
            wheelDown()
            compare(tabsModel.currentIndex, 1)
        }
    }
}
