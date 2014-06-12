/*
 * Copyright 2013-2014 Canonical Ltd.
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

    function test_no_rewrite_data() {
        return [
            {url: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
            {url: "http://ubuntu.com"},
            {url: "https://google.com"},
            {url: "ftp://ubuntu.com"},
        ]
    }

    function test_no_rewrite(data) {
        addressBar.text = data.url
        addressBar.validate()
        compare(addressBar.requestedUrl, data.url)
    }

    function test_add_scheme_data() {
        return [
            {text: "ubuntu.com", requestedUrl: "http://ubuntu.com"},
            {text: "192.168.1.1", requestedUrl: "http://192.168.1.1"},
            {text: "192.168.1.1:8000", requestedUrl: "http://192.168.1.1:8000"},
            {text: "192.168.1.1:8000/dummy.html", requestedUrl: "http://192.168.1.1:8000/dummy.html"},
            {text: "/usr/share/doc/ubuntu-online-tour/index.html", requestedUrl: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
        ]
    }

    function test_add_scheme(data) {
        addressBar.text = data.text
        addressBar.validate()
        compare(addressBar.requestedUrl, data.requestedUrl)
    }

    function test_trim_whitespaces_data() {
        return [
            {text: "   http://ubuntu.com", requestedUrl: "http://ubuntu.com"},
            {text: "http://ubuntu.com  ", requestedUrl: "http://ubuntu.com"},
            {text: "  http://ubuntu.com   ", requestedUrl: "http://ubuntu.com"},
        ]
    }

    function test_trim_whitespaces(data) {
        addressBar.text = data.text
        addressBar.validate()
        compare(addressBar.requestedUrl, data.requestedUrl)
    }

    function test_search_url_data() {
        return [
            {text: "lorem ipsum dolor sit amet", start: "https://google.com", query: "lorem+ipsum+dolor+sit+amet"},
            {text: "ubuntu", start: "https://google.com", query: "ubuntu"},
        ]
    }

    function test_search_url(data) {
        addressBar.text = data.text
        addressBar.validate()
        compare(addressBar.requestedUrl.toString().indexOf(data.start), 0)
        verify(addressBar.requestedUrl.toString().indexOf("q=" + data.query) > 0)
    }

    function test_search_escape_html_entities_data() {
        return [
            {text: "tom & jerry", escaped: "tom+%26+jerry"},
            {text: "a+ rating", escaped: "a%2B+rating"},
            {text: "\"kung fu\"", escaped: "%22kung+fu%22"},
            {text: "surfin' usa", escaped: "surfin'+usa"},
            {text: "to be or not to be?", escaped: "to+be+or+not+to+be%3F"},
            {text: "aléatoire", escaped: "aléatoire"},
        ]
    }

    function test_search_escape_html_entities(data) {
        addressBar.text = data.text
        addressBar.validate()
        verify(addressBar.requestedUrl.toString().indexOf("q=" + data.escaped) > 0)
    }

    function test_url_uppercase_rewrite_data() {
        return [
            {text: "WWW.UBUNTU.COM", requestedUrl: "http://www.ubuntu.com"},
            {text: "EN.WIKIPEDIA.ORG/wiki/Ubuntu", requestedUrl: "http://en.wikipedia.org/wiki/Ubuntu"},
            {text: "EN.WIKIPEDIA.ORG/wiki/UBUNTU", requestedUrl: "http://en.wikipedia.org/wiki/UBUNTU"},
        ]
    }

    function test_url_uppercase_rewrite(data) {
        addressBar.text = data.text
        addressBar.validate()
        compare(addressBar.requestedUrl, data.requestedUrl)
    }

    AddressBar {
        id: addressBar
    }
}
