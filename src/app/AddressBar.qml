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
import Ubuntu.Components 0.1

FocusScope {
    id: addressbar

    property alias text: textField.text
    property url requestedUrl
    property url actualUrl
    signal validated()
    property bool loading
    signal requestReload()
    signal requestStop()

    height: textField.height

    states: [
        State {
            name: "loading"
            when: addressBar.loading
        },
        State {
            name: "editing"
            when: textField.activeFocus
        }
    ]

    TextField {
        id: textField

        anchors.fill: parent

        primaryItem: MouseArea {
            id: __actionButton
            objectName: "actionButton"
            width: __searchIcon.width + units.gu(1)
            height: __searchIcon.height + units.gu(2)
            enabled: textField.text.trim().length > 0
            Image {
                id: __searchIcon
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                opacity: __actionButton.enabled ? 1.0 : 0.2
                source: {
                    switch (addressbar.state) {
                    case "loading":
                        return "assets/cancel.png"
                    case "editing":
                        if (looksLikeAUrl(text.trim())) {
                            return "assets/go-to.png"
                        } else {
                            return "assets/search.png"
                        }
                    default:
                        return "assets/reload.png"
                    }
                }
            }
            onClicked: {
                switch (addressbar.state) {
                case "loading":
                    addressbar.requestStop()
                    break
                case "editing":
                    textField.accepted()
                    break
                default:
                    addressbar.requestReload()
                }
            }
        }

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly

        focus: true
        highlighted: true

        onAccepted: if (__actionButton.enabled) parent.validate()

        function ensureSchemeVisibleWhenUnfocused() {
            // Ensure the beginning of the URL is always visible when unfocused.
            // In the future, we’ll have a smarter address bar that hides the
            // scheme to save some extra space and display more of the
            // meaningful part of the URL (domain name and path).
            if (!activeFocus) {
                cursorPosition = 0
            }
        }
        onActiveFocusChanged: ensureSchemeVisibleWhenUnfocused()
        onTextChanged: ensureSchemeVisibleWhenUnfocused()

        // Make sure that all the text is selected at the first click
        MouseArea {
            anchors {
                fill: parent
                leftMargin: __actionButton.width
            }
            visible: !textField.activeFocus
            onClicked: {
                textField.forceActiveFocus()
                textField.selectAll()
            }
        }
    }

    function looksLikeAUrl(address) {
        var terms = address.split(/\s/)
        if (terms.length > 1) {
            return false
        }
        if (address.substr(0, 1) == "/") {
            return true
        }
        if (address.match(/^https?:\/\//) ||
            address.match(/^file:\/\//) ||
            address.match(/^[a-z]+:\/\//)) {
            return true
        }
        if (address.split('/', 1)[0].match(/\.[a-zA-Z]{2,4}$/)) {
            return true
        }
        if (address.split('/', 1)[0].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}/)) {
            return true
        }
        return false
    }

    function fixUrl(address) {
        var url = address
        if (address.substr(0, 1) == "/") {
            url = "file://" + address
        } else if (address.indexOf("://") == -1) {
            url = "http://" + address
        }
        return url
    }

    function escapeHtmlEntities(query) {
        return query.replace(/\W/, encodeURIComponent)
    }

    function buildSearchUrl(query) {
        var searchUrl = "https://google.com/search?client=ubuntu&q=%1&ie=utf-8&oe=utf-8"
        var terms = query.split(/\s/).map(escapeHtmlEntities)
        return searchUrl.arg(terms.join("+"))
    }

    function validate() {
        var query = text.trim()
        if (looksLikeAUrl(query)) {
            requestedUrl = fixUrl(query)
        } else {
            requestedUrl = buildSearchUrl(query)
        }
        validated()
    }

    onActualUrlChanged: text = actualUrl
}
