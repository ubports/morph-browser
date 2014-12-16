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

TestCase {
    name: "UserAgent"

    function test_get_domain_data() {
        return [
            {url: "http://ubuntu.com", domain: "ubuntu.com"},
            {url: "http://www.ubuntu.com", domain: "www.ubuntu.com"},
            {url: "http://ubuntu.com/", domain: "ubuntu.com"},
            {url: "http://www.ubuntu.com/", domain: "www.ubuntu.com"},
            {url: "ubuntu.com", domain: "ubuntu.com"},
            {url: "ubuntu.com/", domain: "ubuntu.com"},
            {url: "ubuntu.com/phone", domain: "ubuntu.com"},
            {url: "http://ubuntu.com/phone", domain: "ubuntu.com"},
            {url: "www.ubuntu.com/phone", domain: "www.ubuntu.com"},
            {url: "http://ubuntu.com/phone/index.html", domain: "ubuntu.com"},
            {url: "ubuntu.com/phone/index.html", domain: "ubuntu.com"},
            {url: "www.ubuntu.com/phone/index.html", domain: "www.ubuntu.com"},
            {url: "http://ubuntu.com/phone/index.html?foo=bar&baz=bleh", domain: "ubuntu.com"},
        ]
    }
    function test_get_domain(data) {
        compare(userAgent.getDomain(data.url), data.domain)
    }

    function test_get_domains_data() {
        return [
            {domain: "ubuntu.com", domains: ["ubuntu.com", "com"]},
            {domain: "test.example.org", domains: ["test.example.org", "example.org", "org"]},
        ]
    }
    function test_get_domains(data) {
        compare(userAgent.getDomains(data.domain), data.domains)
    }

    function test_get_ua_string_data() {
        return [
            {url: "http://ubuntu.com", ua: userAgent.defaultUA},
            {url: "http://example.org", ua: "full override"},
            {url: "http://example.com/test", ua: "Mozilla/5.0 (Ubuntu Edge; Mobile) WebKit/537.21"},
            {url: "http://www.google.com/", ua: "Mozilla/5.0 (Ubuntu; ble) WebKit/537.21"},
            {url: "https://mail.google.com/", ua: "Mozilla/5.0 (Ubuntu; Touch) WebKit/537.21"},
        ]
    }
    function test_get_ua_string(data) {
        compare(userAgent.getUAString(data.url), data.ua)
    }

    readonly property Item userAgent: loader.item
    Loader {
        id: loader
        source: Qt.resolvedUrl("../../../src/Ubuntu/Components/Extras/Browser/UserAgent01.qml")
        onLoaded : {
            item.defaultUA = "Mozilla/5.0 (Ubuntu; Mobile) WebKit/537.21"
            item.overrides = {
                "example.org": "full override",
                "example.com": ["Ubuntu", "Ubuntu Edge"],
                "google.com": [/mobi/i, "b"],
                "mail.google.com": [/mobile/i, "Touch"],
            }
        }
    }
}
