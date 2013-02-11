/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
    }

    function test_http_no_rewrite() {
        addressBar.url = "http://ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
    }

    function test_https_no_rewrite() {
        addressBar.url = "https://google.com"
        addressBar.validate()
        compare(addressBar.url, "https://google.com")
    }

    function test_no_scheme_rewrite() {
        addressBar.url = "ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
    }

    function test_unhandled_scheme_no_rewrite() {
        addressBar.url = "ftp://ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "ftp://ubuntu.com")
    }

    function test_trim_whitespaces() {
        addressBar.url = "   http://ubuntu.com"
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
        addressBar.url = "http://ubuntu.com  "
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
        addressBar.url = "  http://ubuntu.com   "
        addressBar.validate()
        compare(addressBar.url, "http://ubuntu.com")
    }

    AddressBar {
        id: addressBar
    }
}
