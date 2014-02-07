/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components.Extras.Browser 0.1

TestCase {
    name: "UbuntuWebView"

    function test_custom_UA_override() {
        var url = "http://example.com"
        compare(webview1.getUAString(url), benchmark.getSystemWideUAString(url))
        webview2.customUA = false
        compare(webview2.getUAString(url), benchmark.getSystemWideUAString(url))
        webview2.customUA = true
        compare(webview2.getUAString(url), "custom UA")
    }

    UbuntuWebView {
        id: benchmark
    }

    UbuntuWebView {
        id: webview1
    }

    UbuntuWebView {
        id: webview2

        property bool customUA

        function getUAString(url) {
            if (customUA) {
                return "custom UA"
            } else {
                return getSystemWideUAString(url)
            }
        }
    }
}
