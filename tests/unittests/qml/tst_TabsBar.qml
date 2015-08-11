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
import Ubuntu.Test 1.0
import "../../../src/app/webbrowser"
import webbrowserapp.private 0.1

Item {
    id: root

    width: 600
    height: 50

    TabsModel {
        id: tabsModel
    }

    Component {
        id: tabComponent
        QtObject {
            property url url
            property string title
            property url icon
            function close() { destroy() }
        }
    }

    TabsBar {
        id: tabs
        anchors.fill: parent
        model: tabsModel
        onRequestNewTab: appendTab("", "", "")
        function appendTab(url, title, icon) {
            var tab = tabComponent.createObject(root, {"url": url, "title": title, "icon": icon})
            model.add(tab)
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
            var container = findChild(tabs, "tabsContainer")
            for (var i = 0; i < container.children.length; ++i) {
                var child = container.children[i]
                if ((child.objectName == "tabDelegate") && (child.tabIndex == index)) {
                    return child
                }
            }
            return null
        }

        function cleanup() {
            while (tabsModel.count > 0) {
                tabsModel.remove(0).destroy()
            }
            newTabRequestSpy.clear()
        }

        function populateTabs() {
            for (var i = 0; i < 3; ++i) {
                tabs.appendTab("", "tab " + i, "")
            }
            compare(tabsModel.currentIndex, 2)
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
            populateTabs()
            for (var i = 2; i >= 0; --i) {
                clickItem(getTabDelegate(i))
                compare(tabsModel.currentIndex, i)
            }
        }

        function test_mouse_middle_click() {
            // Middle click closes the tab
            populateTabs()
            for (var i = 2; i >= 0; --i) {
                var tab0 = getTabDelegate(0)
                mouseClick(tab0, centerOf(tab0).x, centerOf(tab0).y, Qt.MiddleButton)
                compare(tabsModel.count, i)
            }
        }

        function test_mouse_wheel() {
            // Wheel events cycle through open tabs
            populateTabs()
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

        function test_drag_tab() {
            populateTabs()

            function dragTab(tab, dx, index) {
                var c = centerOf(tab)
                mouseDrag(tab, c.x, c.y, dx, 0)
                compare(getTabDelegate(index), tab)
                compare(tabsModel.currentIndex, index)
                wait(500)
            }

            // Move the first tab to the right
            var tab = getTabDelegate(0)
            dragTab(tab, tab.width * 0.8, 1)

            // Start a move to the right and release too early
            dragTab(tab, tab.width * 0.3, 1)

            // Start a move to the left and release too early
            dragTab(tab, -tab.width * 0.4, 1)

            // Move the tab all the way to the right and overshoot
            dragTab(tab, tab.width * 3, 2)

            // Move another tab all the way to the left and overshoot
            tab = getTabDelegate(1)
            dragTab(tab, -tab.width * 2, 0)
        }
    }
}
