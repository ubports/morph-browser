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
            settingsObject: QtObject {
                property url homepage
                property string searchEngine
                property int newTabDefaultSection: 0
                property int defaultAudioDevice: 0
                property int defaultVideoDevice: 0
            }
        }
    }

    WebbrowserTestCase {
        name: "TestSettingsPage"
        when: windowShown

        function init() {
            settingsPageLoader.active = true
            waitForRendering(settingsPageLoader.item)
        }

        function cleanup() {
            settingsPageLoader.active = false
        }

        function activateSettingsItem(itemName, pageName) {
            var item = findChild(settingsPage, itemName)
            clickItem(item)
            var page = findChild(settingsPage, pageName)
            waitForRendering(page)
            return page
        }

        function test_goToMediaAccessPage() {
            activateSettingsItem("privacy", "privacySettings")
            return activateSettingsItem("privacy.mediaAccess", "mediaAccessSettings")
        }
    }
}
