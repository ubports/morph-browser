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
import Ubuntu.Components 1.1
import webbrowserapp.private 0.1
import ".."

FocusScope {
    id: addressbar

    property alias icon: favicon.source
    property alias text: textField.text
    property bool bookmarked: false
    property url requestedUrl
    property url actualUrl
    signal validated()
    property bool loading
    signal requestReload()
    signal requestStop()
    signal pressAndHold()
    property string searchUrl
    signal textFieldFocused()

    height: textField.height

    states: [
        State {
            name: "loading"
            when: addressbar.loading
        },
        State {
            name: "editing"
            when: textField.activeFocus
        }
    ]

    TextField {
        id: textField

        anchors.fill: parent

        primaryItem: Item {
            height: textField.height
            width: height

            Favicon {
                id: favicon
                anchors.centerIn: parent
                visible: (addressbar.state == "") && addressbar.actualUrl.toString()
            }

            MouseArea {
                id: actionButton
                objectName: "actionButton"
                anchors.fill: parent
                enabled: addressbar.text
                opacity: enabled ? 1.0 : 0.3

                Icon {
                    id: actionIcon
                    height: parent.height - units.gu(2)
                    width: height
                    anchors.centerIn: parent
                    name: {
                        switch (addressbar.state) {
                        case "loading":
                            return "stop"
                        case "editing":
                            if (addressbar.text && (addressbar.text == addressbar.actualUrl)) {
                                return "reload"
                            } else if (looksLikeAUrl(addressbar.text.trim())) {
                                return "stock_website"
                            } else {
                                return "search"
                            }
                        default:
                            if (!favicon.visible) {
                                if (looksLikeAUrl(addressbar.text.trim())) {
                                    return "stock_website"
                                } else {
                                    return "search"
                                }
                            } else {
                                return ""
                            }
                        }
                    }
                }

                onClicked: {
                    switch (actionIcon.name) {
                    case "":
                        break;
                    case "stop":
                        addressbar.requestStop()
                        break
                    case "reload":
                        addressbar.requestReload()
                        break
                    default:
                        textField.accepted()
                    }
                }
            }
        }

        secondaryItem: Item {
            objectName: "bookmarkToggle"

            height: textField.height
            width: visible ? height : 0

            visible: (addressbar.state == "") && addressbar.actualUrl.toString()

            Icon {
                height: parent.height - units.gu(2)
                width: height
                anchors.centerIn: parent

                name: addressbar.bookmarked ? "starred" : "non-starred"
                color: addressbar.bookmarked ? UbuntuColors.orange : keyColor
            }

            MouseArea {
                id: bookmarkButton
                anchors.fill: parent
                onClicked: addressbar.bookmarked = !addressbar.bookmarked
            }
        }

        font.pixelSize: FontUtils.sizeToPixels("small")
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly

        placeholderText: i18n.tr("search or enter an address")

        // Work around the "fix" for http://pad.lv/1089370 which
        // unsets focus on the TextField when it becomes invisible
        // (to ensure the OSK is hidden).
        focus: true
        onVisibleChanged: {
            if (visible) {
                focus = true
            }
        }

        highlighted: true

        onAccepted: if (addressbar.state != "") parent.validate()

        onActiveFocusChanged: {
            if (activeFocus) {
                addressbar.textFieldFocused();
            } else if (text == addressbar.actualUrl) {
                text = addressbar.simplifyUrl(addressbar.actualUrl)
            }
        }

        // Make sure that all the text is selected at the first click
        MouseArea {
            anchors {
                fill: parent
                leftMargin: actionButton.width
                rightMargin: bookmarkButton.width
            }
            visible: !textField.activeFocus
            onClicked: {
                textField.forceActiveFocus()
                textField.selectAll()
            }
            onPressAndHold: {
                addressbar.pressAndHold()
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
        var terms = query.split(/\s/).map(escapeHtmlEntities)
        return addressbar.searchUrl.replace("{searchTerms}", terms.join("+"))
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

    UrlHelper { id: urlHelper }

    function simplifyUrl(url) {
        var domain = urlHelper.extractDomain(url);
        if (domain.length > 0) return domain;
        else return url;
    }

    onActualUrlChanged: text = simplifyUrl(actualUrl)
}
