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

    function test_search_url() {
        addressBar.url = "lorem ipsum dolor sit amet"
        addressBar.validate()
        compare(addressBar.url.indexOf("http://google.com"), 0)
        verify(addressBar.url.indexOf("q=lorem+ipsum+dolor+sit+amet") > 0)
    }

    function test_search_url_single_word() {
        addressBar.url = "ubuntu"
        addressBar.validate()
        compare(addressBar.url.indexOf("http://google.com"), 0)
        verify(addressBar.url.indexOf("q=ubuntu") > 0)
    }

    function test_search_escape_html_entities() {
        addressBar.url = "tom & jerry"
        addressBar.validate()
        verify(addressBar.url.indexOf("q=tom+%26+jerry") > 0)
        addressBar.url = "a+ rating"
        addressBar.validate()
        verify(addressBar.url.indexOf("q=a%2b+rating") > 0)
        addressBar.url = "\"kung fu\""
        addressBar.validate()
        verify(addressBar.url.indexOf("q=%22kung+fu%22") > 0)
        addressBar.url = "surfin' usa"
        addressBar.validate()
        verify(addressBar.url.indexOf("q=surfin%27+usa") > 0)
        addressBar.url = "to be or not to be?"
        addressBar.validate()
        verify(addressBar.url.indexOf("q=to+be+or+not+to+be%3f") > 0)
    }

    AddressBar {
        id: addressBar
    }
}
