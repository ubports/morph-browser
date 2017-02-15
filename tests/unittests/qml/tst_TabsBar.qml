/*
 * Copyright 2015-2017 Canonical Ltd.
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
import "../../../src/app/webbrowser"
import webbrowserapp.private 0.1

Item {
    id: root

    width: 600
    height: 200
    signal reload(string url)

    readonly property string __platformName: "MOCKED_PLATFORM_NAME"

    TabsModel {
        id: tabsModel

        // These methods are required by the TabsBar component
        property int selectedIndex: currentIndex

        function addTab() {
            tabs.requestNewTab(count, true);
        }

        function moveTab(from, to) {
            if (from == to
                || from < 0 || from >= count
                || to < 0 || to >= count) {
                return;
            }

            move(from, to);
        }

        // Overload removeTab and add moving property so we can tell when
        // the tab is closing due to moving to a new window
        // This is required because we need to avoid destroying the content
        // of that tab that is moved
        function removeTab(index, moving) {
            tabs.tabClosed(index, false);
        }

        function selectTab(index) {
            currentIndex = index;
        }
    }

    Component {
        id: tabComponent
        QtObject {
            id: tab
            property url url
            property string title
            property url icon
            function close() { destroy() }
            function reload() { root.reload(tab.url) }
        }
    }

    TabsBar {
        id: tabs

        // Make the tabs bar smaller than the window and aligned in the middle
        // to leave room for the context menu to pop up and have all its items
        // visible within the screen.
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 50

        model: tabsModel

        onRequestNewTab: insertTab("", "", "", index)

        function appendTab(url, title, icon) {
            insertTab(url, title, icon, model.count)
            model.currentIndex = model.count - 1
        }
        function insertTab(url, title, icon, index) {
            var tab = tabComponent.createObject(root, {"url": url, "title": title, "icon": icon})
            model.insert(tab, index)
        }
    }

    SignalSpy {
        id: newTabRequestSpy
        target: tabs
        signalName: "requestNewTab"
    }

    SignalSpy {
        id: tabClosedSpy
        target: tabs
        signalName: "tabClosed"
    }

    SignalSpy {
        id: reloadSpy
        target: root
        signalName: "reload"
    }

    WebbrowserTestCase {
        name: "TabsBar"
        when: windowShown

        function getMenuItemForAction(menu, actionName) {
            return findChild(menu, "tab_action_" + actionName + "_button")
        }

        function getTabDelegate(index) {
            var listview = findChild(tabs, "tabListView")
            var items = getListItems(listview, "tabDelegate")

            if (index < items.length) {
                return items[index]
            } else {
                return null
            }
        }

        function getTabItem(index) {
            return findChild(getTabDelegate(index), "tabItem")
        }

        function popupMenuOnTab(index) {
            var tab = getTabDelegate(index)
            if (tab) {
                clickItem(tab, Qt.RightButton)
                var menu = findChild(root, "tabContextualActions")
                waitForRendering(menu)
                return menu
            } else return null
        }

        function cleanup() {
            while (tabsModel.count > 0) {
                tabsModel.remove(0).destroy()
            }
            newTabRequestSpy.clear()
            reloadSpy.clear()
            tabClosedSpy.clear()
        }

        function populateTabs() {
            var count = 3
            for (var i = 0; i < count; ++i) {
                tabs.appendTab("", "tab " + i, "")
            }
            compare(tabsModel.currentIndex, count - 1)
            return count
        }

        function test_create_new_tab() {
            var newTabButton = findChild(tabs, "newTabButton")
            for (var i = 0; i < 3; ++i) {
                tryCompare(tabsModel, "count", i)
                clickItem(newTabButton)
            }
            compare(newTabRequestSpy.count, 3)
            compare(newTabRequestSpy.signalArguments[0][0], 0)
            compare(newTabRequestSpy.signalArguments[1][0], 1)
            compare(newTabRequestSpy.signalArguments[2][0], 2)
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
            var count = populateTabs()
            for (var i = 0; i < count; i++) {
                var tab = getTabDelegate(i)
                clickItem(tab, Qt.MiddleButton)
                compare(tabClosedSpy.count, i + 1)
            }
        }

        function test_mouse_right_click() {
            // Right click pops up the contextual actions menu
            populateTabs()
            var menu = popupMenuOnTab(0)
            verify(menu)
            verify(menu.visible)
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

        function test_close_tabs_data() {
            return [
                {button: Qt.LeftButton},
                {button: Qt.MiddleButton}
            ]
        }

        function test_close_tabs(data) {
            var count = populateTabs()
            for (var i = 0; i < count; i++) {
                var tab = getTabDelegate(count - (i + 1))
                var closeButton = findChild(tab, "tabCloseButton")
                clickItem(closeButton, data.button)
                compare(tabClosedSpy.count, i + 1)
                compare(tabClosedSpy.signalArguments[i][0], count - (i + 1))
            }
        }

        function test_drag_tab() {
            populateTabs()

            function dragTab(tab, dx, index) {
                var c = centerOf(tab)

                mousePress(tab, c.x, c.y);

                // Move tab slowly otherwise it can skip the DropArea
                for (var j = 0; j < dx; j++) {
                    mouseMove(tabs, j, c.y)
                    wait(1)
                }

                mouseRelease(tab, c.x + dx, c.y);

                compare(tabsModel.get(index).title, tab.title)
                compare(tabsModel.currentIndex, index)
                wait(500)
            }

            // Move the first tab to the right
            var tab = getTabItem(0)
            dragTab(tab, tab.width, 1)

            // Start a move to the right and release too early
            dragTab(tab, tab.width * 0.3, 1)

            // Start a move to the left and release too early
            dragTab(tab, -tab.width * 0.4, 1)

            // Move the tab all the way to the right and overshoot
            dragTab(tab, tab.width * 3, 2)

            // Move another tab all the way to the left and overshoot
            tab = getTabItem(1)
            dragTab(tab, -tab.width * 2, 0)
        }

        function test_menu_states_on_new_tab() {
            populateTabs()
            var menu = popupMenuOnTab(0)
            var item = getMenuItemForAction(menu, "new_tab")
            verify(item.enabled)
            item = getMenuItemForAction(menu, "reload")
            verify(!item.enabled)
            item = getMenuItemForAction(menu, "close_tab")
            verify(item.enabled)
        }

        function test_menu_states_on_page() {
            tabs.appendTab("http://localhost/", "tab", "")
            var menu = popupMenuOnTab(0)
            var item = getMenuItemForAction(menu, "new_tab")
            verify(item.enabled)
            item = getMenuItemForAction(menu, "reload")
            verify(item.enabled)
            item = getMenuItemForAction(menu, "close_tab")
            verify(item.enabled)
        }

        function test_context_menu_close() {
            populateTabs()
            var menu = popupMenuOnTab(1)
            var item = getMenuItemForAction(menu, "close_tab")
            clickItem(item)
            compare(tabClosedSpy.count, 1)
            compare(tabClosedSpy.signalArguments[0][0], 1)
        }

        function test_context_menu_reload() {
            var baseUrl = "http://localhost/"
            tabs.appendTab(baseUrl + "1", "tab 1", "")
            tabs.appendTab(baseUrl + "2", "tab 2", "")
            var menu = popupMenuOnTab(1)
            var item = getMenuItemForAction(menu, "reload")
            clickItem(item)
            compare(reloadSpy.count, 1)
            compare(reloadSpy.signalArguments[0][0], baseUrl + "2")
        }

        function test_context_menu_new_tab() {
            var baseUrl = "http://localhost/"
            tabs.appendTab(baseUrl + "1", "tab 1", "")
            tabs.appendTab(baseUrl + "2", "tab 2", "")
            var menu = popupMenuOnTab(0)
            var item = getMenuItemForAction(menu, "new_tab")
            clickItem(item)
            compare(newTabRequestSpy.count, 1)
            compare(newTabRequestSpy.signalArguments[0][0], 1)
            compare(tabsModel.count, 3)
            compare(tabsModel.get(0).url, baseUrl + "1")
            compare(tabsModel.get(1).url, "")
            compare(tabsModel.get(2).url, baseUrl + "2")
        }
    }
}
