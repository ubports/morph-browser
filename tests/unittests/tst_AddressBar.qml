/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Browser 0.1

TestCase {
    name: "AddressBar"

    function test_file_no_rewrite() {
        addressBar.url = "file:///usr/share/doc/ubuntu-online-tour/index.html"
        addressBar.validate()
        compare(addressBar.url, "file:///usr/share/doc/ubuntu-online-tour/index.html")
        compare(signalSpy.count, 1)
    }

    function test_http_no_rewrite() {
        addressBar.url = "http://ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
        compare(signalSpy.count, 2)
    }

    function test_https_no_rewrite() {
        addressBar.url = "https://google.com"
        addressBar.validate()
        compare(addressBar.url, "https://google.com")
        compare(signalSpy.count, 3)
    }

    function test_no_scheme_rewrite() {
        addressBar.url = "ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
        compare(signalSpy.count, 4)
    }

    function test_unhandled_scheme_no_rewrite() {
        addressBar.url = "ftp://ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "ftp://ubuntu.com")
        compare(signalSpy.count, 5)
    }

    AddressBar {
        id: addressBar
        SignalSpy {
            id: signalSpy
            target: parent
            signalName: "validated"
        }
    }
}
