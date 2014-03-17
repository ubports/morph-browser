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
    name: "AddressBar"

    function test_file_no_rewrite() {
        addressBar.text = "file:///usr/share/doc/ubuntu-online-tour/index.html"
        addressBar.validate()
        compare(addressBar.requestedUrl, "file:///usr/share/doc/ubuntu-online-tour/index.html")
    }

    function test_http_no_rewrite() {
        addressBar.text = "http://ubuntu.com"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://ubuntu.com")
    }

    function test_https_no_rewrite() {
        addressBar.text = "https://google.com"
        addressBar.validate()
        compare(addressBar.requestedUrl, "https://google.com")
    }

    function test_no_scheme_rewrite() {
        addressBar.text = "ubuntu.com"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://ubuntu.com")
    }

    function test_no_ipadress_scheme_rewrite() {
        addressBar.text = "192.168.1.1"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://192.168.1.1")
        addressBar.text = "192.168.1.1:8000"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://192.168.1.1:8000")
        addressBar.text = "192.168.1.1:8000/dummy.html"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://192.168.1.1:8000/dummy.html")
    }

    function test_unhandled_scheme_no_rewrite() {
        addressBar.text = "ftp://ubuntu.com"
        addressBar.validate()
        compare(addressBar.requestedUrl, "ftp://ubuntu.com")
    }

    function test_trim_whitespaces() {
        addressBar.text = "   http://ubuntu.com"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://ubuntu.com")
        addressBar.text = "http://ubuntu.com  "
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://ubuntu.com")
        addressBar.text = "  http://ubuntu.com   "
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://ubuntu.com")
    }

    function test_search_url() {
        addressBar.text = "lorem ipsum dolor sit amet"
        addressBar.validate()
        compare(addressBar.requestedUrl.toString().indexOf("https://google.com"), 0)
        verify(addressBar.requestedUrl.toString().indexOf("q=lorem+ipsum+dolor+sit+amet") > 0)
    }

    function test_search_url_single_word() {
        addressBar.text = "ubuntu"
        addressBar.validate()
        compare(addressBar.requestedUrl.toString().indexOf("https://google.com"), 0)
        verify(addressBar.requestedUrl.toString().indexOf("q=ubuntu") > 0)
    }

    function test_search_escape_html_entities() {
        addressBar.text = "tom & jerry"
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=tom+%26+jerry") > 0)
        addressBar.text = "a+ rating"
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=a%2B+rating") > 0)
        addressBar.text = "\"kung fu\""
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=%22kung+fu%22") > 0)
        addressBar.text = "surfin' usa"
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=surfin%27+usa") > 0)
        addressBar.text = "to be or not to be?"
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=to+be+or+not+to+be%3F") > 0)
    }

    function test_url_uppercase_rewrite() {
        addressBar.text = "WWW.UBUNTU.COM"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://www.ubuntu.com")

        addressBar.text = "EN.WIKIPEDIA.ORG/wiki/Ubuntu"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://en.wikipedia.org/wiki/Ubuntu")

        addressBar.text = "EN.WIKIPEDIA.ORG/wiki/UBUNTU"
        addressBar.validate()
        compare(addressBar.requestedUrl, "http://en.wikipedia.org/wiki/UBUNTU")
    }

    function test_local_file_no_scheme() {
        addressBar.text = "/usr/share/doc/ubuntu-online-tour/index.html"
        addressBar.validate()
        compare(addressBar.requestedUrl, "file:///usr/share/doc/ubuntu-online-tour/index.html")
    }

    AddressBar {
        id: addressBar
    }
}
