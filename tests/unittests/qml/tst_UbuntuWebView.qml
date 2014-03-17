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
        compare(webview1.getUAString(), undefined)
        // passing a 'url' parameter to getUAString()
        // (as was the API before) shouldn’t hurt:
        compare(webview1.getUAString("http://example.com"), undefined)
        verify(webview1.context.userAgent !== undefined)
        compare(webview2.context.userAgent, "custom UA")
    }

    UbuntuWebView {
        id: webview1
    }

    UbuntuWebView {
        id: webview2

        function getUAString(url) {
            return "custom UA"
        }
    }
}
