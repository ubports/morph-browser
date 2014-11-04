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

Item {
    width: 300
    height: 100

    FocusScope {
        anchors.fill: parent

        AddressBar {
            id: addressBar

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: parent.height / 2

            searchUrl: "http://www.ubuntu.com/search?q={searchTerms}"

            function get_clear_button() {
                // not exposed through the TextField API
                for (var i in addressBar.textField.children) {
                    var child = addressBar.textField.children[i]
                    if (child.objectName == "clear_button") {
                        return child
                    }
                }
                return null
            }
        }

        // only exists to steal focus from the address bar
        TextInput {
            id: textInput

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: parent.height / 2
        }
    }

    SignalSpy {
        id: validatedSpy
        target: addressBar
        signalName: "validated"
    }

    TestCase {
        name: "AddressBar"
        when: windowShown

        function init() {
            validatedSpy.clear()
            // Ensure the address bar has active focus
            mouseClick(addressBar, addressBar.width / 2, addressBar.height / 2)
            verify(addressBar.activeFocus)
            // Clear it
            var clearButton = addressBar.get_clear_button()
            verify(clearButton != null)
            mouseClick(clearButton, clearButton.width / 2, clearButton.height / 2)
            compare(addressBar.text, "")
            // Ensure it still has active focus
            verify(addressBar.activeFocus)
        }

        function typeString(str) {
            verify(addressBar.activeFocus)
            for (var i = 0; i < str.length; ++i) {
                keyClick(str[i])
            }
        }

        function test_no_rewrite_data() {
            return [
                {url: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
                {url: "http://ubuntu.com"},
                {url: "https://google.com"},
                {url: "ftp://ubuntu.com"},
            ]
        }

        function test_no_rewrite(data) {
            typeString(data.url)
            compare(addressBar.text, data.url)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
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
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
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
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_search_url_data() {
            return [
                {text: "lorem ipsum dolor sit amet", start: "http://www.ubuntu.com", query: "lorem+ipsum+dolor+sit+amet"},
                {text: "ubuntu", start: "http://www.ubuntu.com", query: "ubuntu"},
            ]
        }

        function test_search_url(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
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
            ]
        }

        function test_search_escape_html_entities(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
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
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_simplify_data() {
            return [
                {text: "ubuntu.com", url: "http://www.ubuntu.com"},
                {text: "ubuntu.com", url: "http://www.ubuntu.com/"},
                {text: "ubuntu.com", url: "http://www.ubuntu.com:80"},
                {text: "ubuntuwww.com", url: "http://www.ubuntuwww.com"},
                {text: "www.com", url: "http://www.com"},
                {text: "ubuntu.com", url: "http://user@www.ubuntu.com"},
                {text: "ubuntu.com", url: "http://user:password@www.ubuntu.com"},
                {text: "ubuntu.com", url: "http://user:password@www.ubuntu.com:80"},
                {text: "file:///home/phablet/", url: "file:///home/phablet/"},
                {text: "en.wikipedia.org", url: "http://en.wikipedia.org/wiki/Ubuntu"},
                {text: "en.wikipedia.org", url: "en.wikipedia.org"},
                {text: "en.wikipedia.org", url: "en.wikipedia.org/wiki/Foo"}
            ]
        }

        function test_simplify(data) {
            typeString(data.url)
            compare(addressBar.text, data.url)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.text, data.text)
        }

        function test_action_button() {
            verify(!addressBar.actionButton.enabled)
            keyClick(Qt.Key_U)
            verify(addressBar.text != "")
            verify(addressBar.actionButton.enabled)
        }

        function test_click_selects_all() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            mouseClick(textInput, textInput.width / 2, textInput.height / 2)
            verify(!addressBar.activeFocus)
            mouseClick(addressBar, addressBar.width / 2, addressBar.height / 2)
            compare(addressBar.textField.selectedText, url)
        }

        function test_second_click_deselect_text() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            mouseClick(textInput, textInput.width / 2, textInput.height / 2)
            verify(!addressBar.activeFocus)
            mouseClick(addressBar, addressBar.width / 2, addressBar.height / 2)
            compare(addressBar.textField.selectedText, url)
            mouseClick(addressBar, addressBar.width / 2, addressBar.height / 2)
            compare(addressBar.textField.selectedText, "")
            verify(addressBar.textField.cursorPosition > 0)
        }

        function test_click_action_button_does_not_select_all() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            mouseClick(textInput, textInput.width / 2, textInput.height / 2)
            verify(!addressBar.activeFocus)
            mouseClick(addressBar.actionButton, addressBar.actionButton.width / 2, addressBar.actionButton.height / 2)
            compare(addressBar.textField.selectedText, "")
        }

        function test_state_changes() {
            compare(addressBar.state, "editing")
            mouseClick(textInput, textInput.width / 2, textInput.height / 2)
            compare(addressBar.state, "")
            addressBar.loading = true
            compare(addressBar.state, "loading")
            addressBar.loading = false
            compare(addressBar.state, "")
        }
    }
}
