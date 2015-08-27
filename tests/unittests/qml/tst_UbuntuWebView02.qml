/*
 * Copyright 2013-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Web 0.2

Item {
    id: root

    width: 200
    height: 200

    Component {
        id: webviewComponent
        WebView {
            anchors.fill: parent
        }
    }

    ActionList {
        id: actionList
        Action {
            id: action1
        }
        Action {
            id: action2
        }
    }

    readonly property string htmlWithHyperlink: '<html><body style="margin: 0"><a href="http://example.org/"><div style="height: 100%"></div></a></body></html>'

    UbuntuTestCase {
        name: "UbuntuWebView02"
        when: windowShown

        property var webview: null

        function init() {
            webview = webviewComponent.createObject(root)
        }

        function cleanup() {
            webview.destroy()
        }

        function test_context_singleton() {
            var other = webviewComponent.createObject(root)
            compare(other.context, webview.context)
            other.destroy()
        }

        function rightClickWebview() {
            var center = centerOf(webview)
            mouseClick(webview, center.x, center.y, Qt.RightButton)
            // give the context menu a chance to appear before carrying on
            wait(500)
        }

        function getContextMenu() {
            return findChild(webview, "contextMenu")
        }

        function dismissContextMenu() {
            var center = centerOf(webview)
            mouseClick(webview, center.x, center.y)
            wait(500)
            compare(getContextMenu(), null)
        }

        function test_no_contextual_actions() {
            webview.loadHtml(root.htmlWithHyperlink, "file:///")
            tryCompare(webview, "loading", false)
            rightClickWebview()
            compare(getContextMenu(), null)
        }

        function test_contextual_actions() {
            webview.contextualActions = actionList
            webview.loadHtml(root.htmlWithHyperlink, "file:///")
            tryCompare(webview, "loading", false)
            rightClickWebview()
            compare(getContextMenu().actions, actionList)
            compare(webview.contextualData.href, "http://example.org/")
            dismissContextMenu()
            compare(webview.contextualData.href, "")
        }

        function test_contextual_actions_all_disabled() {
            webview.contextualActions = actionList
            action1.enabled = false
            action2.enabled = false
            webview.loadHtml(root.htmlWithHyperlink, "file:///")
            tryCompare(webview, "loading", false)
            rightClickWebview()
            compare(getContextMenu(), null)
            action1.enabled = true
            action2.enabled = true
        }
    }
}
