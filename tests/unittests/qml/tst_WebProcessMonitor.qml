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
import com.canonical.Oxide 1.8 as Oxide
import "../../../src/app"

WebProcessMonitor {
    id: monitor

    Item {
        id: webviewMock

        property int webProcessStatus

        property int reloadCalled
        function reload() {
            webProcessStatus = Oxide.WebView.WebProcessRunning
            reloadCalled++
        }
    }

    TestCase {
        name: "WebProcessMonitor"

        function init() {
            webviewMock.webProcessStatus = Oxide.WebView.WebProcessRunning
            webviewMock.reloadCalled = 0
        }

        function test_no_webview() {
            monitor.webview = null
            compare(monitor.killedRetries, 0)
            verify(!monitor.killed)
            verify(!monitor.crashed)
        }

        function test_killed() {
            monitor.webview = webviewMock
            compare(monitor.killedRetries, 0)

            webviewMock.webProcessStatus = Oxide.WebView.WebProcessKilled
            verify(monitor.killed)
            verify(!monitor.crashed)
            tryCompare(monitor, "killedRetries", 1)
            tryCompare(webviewMock, "reloadCalled", 1)
            verify(!monitor.killed)
            verify(!monitor.crashed)
            compare(monitor.killedRetries, 1)

            webviewMock.webProcessStatus = Oxide.WebView.WebProcessKilled
            verify(monitor.killed)
            verify(!monitor.crashed)
            compare(monitor.killedRetries, 1)
            compare(webviewMock.reloadCalled, 1)
        }

        function test_crashed() {
            monitor.webview = webviewMock
            compare(monitor.killedRetries, 0)

            webviewMock.webProcessStatus = Oxide.WebView.WebProcessCrashed
            verify(!monitor.killed)
            verify(monitor.crashed)
            compare(monitor.killedRetries, 0)
            compare(webviewMock.reloadCalled, 0)

            webviewMock.webProcessStatus = Oxide.WebView.WebProcessRunning
            verify(!monitor.killed)
            verify(!monitor.crashed)
            compare(monitor.killedRetries, 0)
            compare(webviewMock.reloadCalled, 0)
        }

        function test_change_webview() {
            monitor.webview = webviewMock
            compare(monitor.killedRetries, 0)
            verify(!monitor.killed)
            verify(!monitor.crashed)

            webviewMock.webProcessStatus = Oxide.WebView.WebProcessKilled
            verify(monitor.killed)
            verify(!monitor.crashed)
            tryCompare(monitor, "killedRetries", 1)

            monitor.webview = null
            compare(monitor.killedRetries, 0)
            verify(!monitor.killed)
            verify(!monitor.crashed)
        }
    }
}
