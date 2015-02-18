/*
 * Copyright 2014-2015 Canonical Ltd.
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
import "../../../src/app/webbrowser"

Item {
    id: root

    width: 200
    height: 200

    Component {
        id: tabComponent

        BrowserTab {
            webviewComponent: Item {
                property url url
                property string title
                property url icon
                property var request
                property string currentState
            }
            readonly property bool webviewPresent: webview
        }
    }

    TestCase {
        name: "BrowserTab"
        when: windowShown

        function test_unique_ids() {
            var tab = tabComponent.createObject(root)
            var tab2 = tabComponent.createObject(root)
            verify(tab.uniqueId)
            verify(tab2.uniqueId)
            verify(tab.uniqueId !== tab2.uniqueId)
            tab.destroy()
            tab2.destroy()
        }

        function test_load_unload() {
            var tab = tabComponent.createObject(root)
            verify(!tab.webviewPresent)

            tab.initialUrl = "http://example.org"
            tab.load()
            tryCompare(tab, 'webviewPresent', true)
            compare(tab.webview.url, "http://example.org")

            tab.webview.url = "http://ubuntu.com"
            tab.webview.title = "Ubuntu"
            tab.webview.currentState = "foobar"
            tab.unload()
            tryCompare(tab, 'webviewPresent', false)
            compare(tab.initialUrl, "http://ubuntu.com")
            compare(tab.initialTitle, "Ubuntu")
            compare(tab.restoreState, "foobar")

            tab.destroy()
        }

        function test_create_with_request() {
            var tab = tabComponent.createObject(root, {'request': "foobar"})
            tryCompare(tab, 'webviewPresent', true)
            verify(tab.webviewPresent)
            compare(tab.webview.request, "foobar")
            tab.destroy()
        }
    }
}
