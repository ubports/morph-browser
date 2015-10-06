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
import webbrowserapp.private 0.1
import webbrowsertest.private 0.1
import "../../../src/app/webbrowser"

Item {
    width: 400
    height: 600

    property var settingsPage: settingsPageLoader.item

    Loader {
        id: settingsPageLoader
        anchors.fill: parent
        active: false
        sourceComponent: SettingsPage {
            anchors.fill: parent

            // NOTE: the following properties are not necessary for the tests
            // currently in this file, but if we don't provide them a lot of
            // warnings will be generated.
            // Ideally either more tests that use them will be added or the code
            // in SettingsPage will be refactored to cope with the missing
            // settings.
            historyModel: HistoryModelMock {
                databasePath: ":memory:"
            }
            settingsObject: QtObject {
                property url homepage
                property string searchEngine
                property int newTabDefaultSection: 0
            }
        }
    }

    UbuntuTestCase {
        name: "TestSettingsPage"
        when: windowShown

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function swipeItemRight(item) {
            var center = centerOf(item)
            var dx = item.width * 0.5
            mousePress(item, center.x, center.y)
            mouseMoveSlowly(item, center.x, center.y, dx, 0, 10, 0.01)
            mouseRelease(item, center.x + dx, center.y)
        }

        function init() {
            settingsPageLoader.active = true
            waitForRendering(settingsPageLoader.item)
        }

        function cleanup() {
            settingsPageLoader.active = false
        }

        function getListItems(name, itemName) {
            var list = findChild(settingsPage, name)
            var items = []
            if (list) {
                // ensure all the delegates are created
                list.cacheBuffer = list.count * 1000

                // In some cases the ListView might add other children to the
                // contentItem, so we filter the list of children to include
                // only actual delegates (names for delegates in this case
                // follow the pattern "name_index")
                var children = list.contentItem.children
                for (var i = 0; i < children.length; i++) {
                    if (children[i].objectName.indexOf(itemName) == 0) {
                        items.push(children[i])
                    }
                }
            }
            return items
        }

        function activateSettingsItem(itemName, pageName) {
            var item = findChild(settingsPage, itemName)
            clickItem(item)
            var page = findChild(settingsPage, pageName)
            waitForRendering(page)
            return page
        }

        function goToMediaAccessPage() {
            activateSettingsItem("privacy", "privacySettings")
            return activateSettingsItem("privacy.mediaAccess", "mediaAccessSettings")
        }
    }
}
