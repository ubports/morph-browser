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
import Ubuntu.Test 1.0
import "../../../src/app/webbrowser"

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

            editing: activeFocus
            canSimplifyText: true

            findController: QtObject {
                property int current
                property int count
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

    UbuntuTestCase {
        name: "AddressBar"
        when: windowShown

        function clickItem(item) {
            var center = centerOf(item)
            mouseClick(item, center.x, center.y)
        }

        function init() {
            addressBar.actualUrl = ""
            validatedSpy.clear()
            // Ensure the address bar has active focus
            clickItem(addressBar)
            verify(addressBar.activeFocus)
            // Clear it
            var clearButton = findChild(addressBar, "clear_button")
            verify(clearButton != null)
            clickItem(clearButton)
            compare(addressBar.text, "")
            // Ensure it still has active focus
            verify(addressBar.activeFocus)
        }

        function test_validUrlShouldNotBeRewritten_data() {
            return [
                {url: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
                {url: "http://ubuntu.com"},
                {url: "https://google.com"},
                {url: "ftp://ubuntu.com"},
                {url: "about:blank"},
                {url: "data:,A brief note"},
                {url: "http://com.google"}
            ]
        }

        function test_validUrlShouldNotBeRewritten(data) {
            typeString(data.url)
            compare(addressBar.text, data.url)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.url)
        }

        function test_urlWithoutSchemeShouldBeRewritten_data() {
            return [
                {text: "ubuntu.com", requestedUrl: "http://ubuntu.com"},
                {text: "192.168.1.1", requestedUrl: "http://192.168.1.1"},
                {text: "192.168.1.1:8000", requestedUrl: "http://192.168.1.1:8000"},
                {text: "192.168.1.1:8000/dummy.html", requestedUrl: "http://192.168.1.1:8000/dummy.html"},
                {text: "/usr/share/doc/ubuntu-online-tour/index.html", requestedUrl: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
            ]
        }

        function test_urlWithoutSchemeShouldBeRewritten(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_leadingAndTrailingWhitespacesShouldBeTrimmed_data() {
            return [
                {text: "   http://ubuntu.com", requestedUrl: "http://ubuntu.com"},
                {text: "http://ubuntu.com  ", requestedUrl: "http://ubuntu.com"},
                {text: "  http://ubuntu.com   ", requestedUrl: "http://ubuntu.com"},
            ]
        }

        function test_leadingAndTrailingWhitespacesShouldBeTrimmed(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_searchQueryShouldBeRewritten_data() {
            return [
                {text: "lorem ipsum dolor sit amet", start: "http://www.ubuntu.com", query: "lorem+ipsum+dolor+sit+amet"},
                {text: "ubuntu", start: "http://www.ubuntu.com", query: "ubuntu"},
            ]
        }

        function test_searchQueryShouldBeRewritten(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl.toString().indexOf(data.start), 0)
            verify(addressBar.requestedUrl.toString().indexOf("q=" + data.query) > 0)
        }

        function test_htmlEntitiesShouldBeEscapedInSearchQueries_data() {
            return [
                {text: "tom & jerry", escaped: "tom+%26+jerry"},
                {text: "a+ rating", escaped: "a%2B+rating"},
                {text: "\"kung fu\"", escaped: "%22kung+fu%22"},
                {text: "surfin' usa", escaped: "surfin'+usa"},
                {text: "to be or not to be?", escaped: "to+be+or+not+to+be%3F"},
            ]
        }

        function test_htmlEntitiesShouldBeEscapedInSearchQueries(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            verify(addressBar.requestedUrl.toString().indexOf("q=" + data.escaped) > 0)
        }

        function test_uppercaseDomainsShouldBeRewritten_data() {
            return [
                {text: "WWW.UBUNTU.COM", requestedUrl: "http://www.ubuntu.com"},
                {text: "EN.WIKIPEDIA.ORG/wiki/Ubuntu", requestedUrl: "http://en.wikipedia.org/wiki/Ubuntu"},
                {text: "EN.WIKIPEDIA.ORG/wiki/UBUNTU", requestedUrl: "http://en.wikipedia.org/wiki/UBUNTU"},
            ]
        }

        function test_uppercaseDomainsShouldBeRewritten(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_uppercaseSchemeShouldBeRewritten_data() {
            return [
                {text: "HTTP://WWW.UBUNTU.COM", requestedUrl: "http://www.ubuntu.com"},
                {text: "HTTP://www.ubuntu.com", requestedUrl: "http://www.ubuntu.com"},
                {text: "HTTPS://www.ubuntu.com", requestedUrl: "https://www.ubuntu.com"},
                {text: "FILE:///usr/share/doc/ubuntu-online-tour/index.html", requestedUrl: "file:///usr/share/doc/ubuntu-online-tour/index.html"},
                {text: "FTP://ubuntu.com", requestedUrl: "ftp://ubuntu.com"},
                {text: "ABOUT:BLANK", requestedUrl: "about:blank"},
                {text: "DATA:,A brief note", requestedUrl: "data:,A brief note"},
                {text: "HTTP://com.GOOGLE", requestedUrl: "http://com.google"}
            ]
        }

        function test_uppercaseSchemeShouldBeRewritten(data) {
            typeString(data.text)
            compare(addressBar.text, data.text)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            compare(addressBar.requestedUrl, data.requestedUrl)
        }

        function test_urlShouldBeSimplifiedWhenUnfocused_data() {
            return [
                {input: "http://www.ubuntu.com",
                 simplified: "ubuntu.com",
                 actualUrl: "http://www.ubuntu.com"},
                {input: "http://www.ubuntu.com/",
                 simplified: "ubuntu.com",
                 actualUrl: "http://www.ubuntu.com/"},
                {input: "http://www.ubuntu.com:80",
                 simplified: "ubuntu.com",
                 actualUrl: "http://www.ubuntu.com:80"},
                {input: "http://www.ubuntuwww.com",
                 simplified: "ubuntuwww.com",
                 actualUrl: "http://www.ubuntuwww.com"},
                {input: "http://www.com",
                 simplified: "www.com",
                 actualUrl: "http://www.com"},
                {input: "http://user@www.ubuntu.com",
                 simplified: "ubuntu.com",
                 actualUrl: "http://user@www.ubuntu.com"},
                {input: "http://user:password@www.ubuntu.com",
                 simplified: "ubuntu.com",
                 actualUrl: "http://user:password@www.ubuntu.com"},
                {input: "http://user:password@www.ubuntu.com:80",
                 simplified: "ubuntu.com",
                 actualUrl: "http://user:password@www.ubuntu.com:80"},
                {input: "file:///home/phablet/",
                 simplified: "file:///home/phablet/",
                 actualUrl: "file:///home/phablet/"},
                {input: "http://en.wikipedia.org/wiki/Ubuntu",
                 simplified: "en.wikipedia.org",
                 actualUrl: "http://en.wikipedia.org/wiki/Ubuntu"},
                {input: "en.wikipedia.org",
                 simplified: "en.wikipedia.org",
                 actualUrl: "http://en.wikipedia.org"},
                {input: "en.wikipedia.org/wiki/Foo",
                 simplified: "en.wikipedia.org",
                 actualUrl: "http://en.wikipedia.org/wiki/Foo"},
                {input: "http://com.google",
                 simplified: "com.google",
                 actualUrl: "http://com.google"},
            ]
        }

        function test_urlShouldBeSimplifiedWhenUnfocused(data) {
            typeString(data.input)
            compare(addressBar.text, data.input)
            keyClick(Qt.Key_Return)
            validatedSpy.wait()
            addressBar.actualUrl = addressBar.requestedUrl
            compare(addressBar.text, data.input)
            clickItem(textInput)
            compare(addressBar.text, data.simplified)
            clickItem(addressBar)
            compare(addressBar.text, data.actualUrl)
        }

        function test_shouldBeClearedWhenFocusedIfActualUrlIsCleared() {
            // https://launchpad.net/bugs/1456199
            var text = "http://example.org"
            typeString(text)
            compare(addressBar.text, text)
            verify(addressBar.activeFocus)
            addressBar.actualUrl = text
            verify(addressBar.activeFocus)
            addressBar.actualUrl = ""
            verify(addressBar.activeFocus)
            compare(addressBar.text, "")
        }

        function test_actionButtonShouldBeDisabledWhenEmpty() {
            verify(!addressBar.__actionButton.enabled)
            keyClick(Qt.Key_U)
            verify(addressBar.text != "")
            verify(addressBar.__actionButton.enabled)
        }

        function test_clickingWhenUnfocusedShouldSelectAll() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            addressBar.actualUrl = url
            clickItem(textInput)
            verify(!addressBar.activeFocus)
            clickItem(addressBar)
            compare(addressBar.__textField.selectedText, url)
        }

        function test_clickingWhenFocusedShouldDeselectText() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            addressBar.actualUrl = url
            clickItem(textInput)
            verify(!addressBar.activeFocus)
            clickItem(addressBar)
            compare(addressBar.__textField.selectedText, url)
            clickItem(addressBar)
            compare(addressBar.__textField.selectedText, "")
            verify(addressBar.__textField.cursorPosition > 0)
        }

        function test_clickingActionButtonWhenUnfocusedShouldNotSelectAll() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            clickItem(textInput)
            verify(!addressBar.activeFocus)
            clickItem(addressBar.__actionButton)
            compare(addressBar.__textField.selectedText, "")
        }

        function test_shouldNotAllowBookmarkingWhenEmpty() {
            // focused
            var toggle = addressBar.__bookmarkToggle
            verify(!toggle.visible)
            // and unfocused
            clickItem(textInput)
            verify(!toggle.visible)
        }

        function test_shouldNotAllowBookmarkingWhileFocused() {
            addressBar.actualUrl = "http://example.org"
            var toggle = addressBar.__bookmarkToggle
            verify(!toggle.visible)
            clickItem(textInput)
            verify(toggle.visible)
        }

        function test_togglingIndicatorShouldBookmark() {
            addressBar.actualUrl = "http://example.org"
            clickItem(textInput)
            verify(!addressBar.bookmarked)
            var toggle = addressBar.__bookmarkToggle
            clickItem(toggle)
            verify(addressBar.bookmarked)
            clickItem(toggle)
            verify(!addressBar.bookmarked)
        }

        function test_unfocusingWhileEditingShouldResetUrl() {
            var url = "http://example.org/"
            typeString(url)
            compare(addressBar.text, url)
            addressBar.actualUrl = url
            var clearButton = findChild(addressBar, "clear_button")
            verify(clearButton != null)
            clickItem(clearButton)
            compare(addressBar.text, "")
            clickItem(textInput)
            compare(addressBar.text, "example.org")
            clickItem(addressBar)
            compare(addressBar.text, url)
        }

        function test_exitingFindInPageRestoresUrl() {
            addressBar.actualUrl = "http://example.org/"
            addressBar.findInPageMode = true
            verify(addressBar.activeFocus)
            compare(addressBar.text, "")
            typeString("hello")
            addressBar.findInPageMode = false
            compare(addressBar.text, "example.org")
        }
    }
}
