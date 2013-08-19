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
import "undertest"

TestCase {
    name: "UserAgent"

    function test_get_domain() {
        compare(userAgent.getDomain("http://ubuntu.com"), "ubuntu.com")
        compare(userAgent.getDomain("http://www.ubuntu.com"), "www.ubuntu.com")
        compare(userAgent.getDomain("http://ubuntu.com/"), "ubuntu.com")
        compare(userAgent.getDomain("http://www.ubuntu.com/"), "www.ubuntu.com")
        compare(userAgent.getDomain("ubuntu.com"), "ubuntu.com")
        compare(userAgent.getDomain("ubuntu.com/"), "ubuntu.com")
        compare(userAgent.getDomain("ubuntu.com/phone"), "ubuntu.com")
        compare(userAgent.getDomain("http://ubuntu.com/phone"), "ubuntu.com")
        compare(userAgent.getDomain("www.ubuntu.com/phone"), "www.ubuntu.com")
        compare(userAgent.getDomain("http://ubuntu.com/phone/index.html"), "ubuntu.com")
        compare(userAgent.getDomain("ubuntu.com/phone/index.html"), "ubuntu.com")
        compare(userAgent.getDomain("www.ubuntu.com/phone/index.html"), "www.ubuntu.com")
        compare(userAgent.getDomain("http://ubuntu.com/phone/index.html?foo=bar&baz=bleh"), "ubuntu.com")
    }

    function test_ua_unmodified() {
        compare(userAgent.getUAString("http://ubuntu.com"), userAgent.defaultUA)
    }

    function test_ua_full_override() {
        compare(userAgent.getUAString("http://example.org"), "full override")
    }

    function test_ua_string_replace() {
        compare(userAgent.getUAString("http://example.com/test"),
                "Mozilla/5.0 (Ubuntu Edge; Mobile) WebKit/537.21")
    }

    function test_ua_regexp_replace() {
        compare(userAgent.getUAString("http://www.google.com/"),
                "Mozilla/5.0 (Ubuntu; ble) WebKit/537.21")
    }

    UserAgent {
        id: userAgent

        defaultUA: "Mozilla/5.0 (Ubuntu; Mobile) WebKit/537.21"

        overrides: {
            "example.org": "full override",
            "example.com": ["Ubuntu", "Ubuntu Edge"],
            "google.com": [/mobi/i, "b"],
        }
    }
}
