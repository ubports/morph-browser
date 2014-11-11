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
import Ubuntu.Components.Popups 1.0
import com.canonical.Oxide 1.0 as Oxide
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
    property string searchUrl

    property var securityStatus: null

    // XXX: for testing purposes only, do not use to modify the
    // contents/behaviour of the internals of the component.
    readonly property Item __textField: textField
    readonly property Item __actionButton: actionButton
    readonly property Item __bookmarkToggle: bookmarkToggle

    height: textField.height

    states: [
        State {
            name: "loading"
            when: addressbar.loading
        },
        State {
            name: "editing"
            when: addressbar.activeFocus
        }
    ]

    TextField {
        id: textField

        anchors.fill: parent

        primaryItem: Item {
            width: iconsRow.width
            height: iconsRow.height
            Row {
                id: iconsRow
                Item {
                    height: textField.height
                    width: height
                    visible: (addressbar.state != "") || !internal.secureConnection || !internal.securityWarning

                    Favicon {
                        id: favicon
                        anchors.centerIn: parent
                        visible: (addressbar.state == "") && addressbar.actualUrl.toString() && !internal.securityWarning
                    }

                    Item {
                        id: certificatePopoverPositioner
                        anchors.bottom: favicon.bottom
                        anchors.horizontalCenter: favicon.horizontalCenter
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
                                    } else if (internal.looksLikeAUrl(addressbar.text.trim())) {
                                        return "stock_website"
                                    } else {
                                        return "search"
                                    }
                                default:
                                    if (!favicon.visible) {
                                        if (internal.looksLikeAUrl(addressbar.text.trim())) {
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
                                break
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

                Item {
                    id: securityDisplay
                    height: textField.height
                    width: securityIcon.width
                    visible: internal.secureConnection && (addressbar.state == "")

                    Icon {
                        id: securityIcon
                        anchors.centerIn: parent
                        height: parent.height - units.gu(2)
                        width: height
                        name: "network-secure"
                    }
                }

                Item {
                    height: textField.height
                    width: warningIcon.width
                    visible: internal.securityWarning && (addressbar.state == "")

                    Icon {
                        id: warningIcon
                        anchors.centerIn: parent
                        height: parent.height - units.gu(2)
                        width: height
                        name: "security-alert"
                    }
                }
            }

            MouseArea {
                enabled: securityDisplay.visible && addressbar.state != "editing" && addressbar.state != "loading"
                anchors.fill: parent

                onClicked: addressbar.showSecurityCertificateDetails()
            }
        }

        secondaryItem: Item {
            id: bookmarkToggle
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

        onAccepted: if (addressbar.state != "") internal.validate()

        // Make sure that all the text is selected at the first click
        MouseArea {
            anchors {
                fill: parent
                leftMargin: iconsRow.width
                rightMargin: bookmarkButton.width
            }
            visible: !textField.activeFocus
            onClicked: {
                textField.forceActiveFocus()
                textField.selectAll()
            }
        }
    }

    QtObject {
        id: internal

        readonly property int securityLevel: addressbar.securityStatus ? addressbar.securityStatus.securityLevel : Oxide.SecurityStatus.SecurityLevelNone
        readonly property bool secureConnection: addressbar.securityStatus ? (securityLevel == Oxide.SecurityStatus.SecurityLevelSecure || securityLevel == Oxide.SecurityStatus.SecurityLevelSecureEV || securityLevel == Oxide.SecurityStatus.SecurityLevelWarning) : false
        readonly property bool securityWarning: addressbar.securityStatus ? (securityLevel == Oxide.SecurityStatus.SecurityLevelWarning) : false

        property var securityCertificateDetails: null

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
            var terms = query.split(/\s/).map(internal.escapeHtmlEntities)
            return addressbar.searchUrl.replace("{searchTerms}", terms.join("+"))
        }

        function validate() {
            var query = text.trim()
            if (internal.looksLikeAUrl(query)) {
                requestedUrl = internal.fixUrl(query)
            } else {
                requestedUrl = internal.buildSearchUrl(query)
            }
            validated()
        }

        function simplifyUrl(url) {
            var urlString = url.toString()
            var hasProtocol = urlString.indexOf("://") != -1
            var domain
            if (hasProtocol) {
                if (urlString.split("://")[0] == "file") {
                    // Don't process file:// urls
                    return url
                }
                domain = urlString.split('/')[2]
            } else {
                domain = urlString.split('/')[0]
            }
            if (typeof domain !== 'undefined' && domain.length > 0) {
                // Remove user component if present
                var userRemoved = domain.split('@')[1]
                if (typeof userRemoved !== 'undefined') {
                    domain = userRemoved
                }
                // Remove port number if present
                domain = domain.split(':')[0]
                if (domain.lastIndexOf('.') != 3) { // http://www.com shouldn't be trimmed
                    domain = domain.replace(/^www\./, "")
                }
                return domain
            } else {
                return url
            }
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            text = actualUrl
        } else if (!loading && actualUrl.toString()) {
            text = internal.simplifyUrl(actualUrl)
        }
    }

    onActualUrlChanged: {
        if (state != "editing") {
            text = internal.simplifyUrl(actualUrl)
        }
    }
    onRequestedUrlChanged: {
        if (state != "editing") {
            text = internal.simplifyUrl(requestedUrl)
        }
    }

    function showSecurityCertificateDetails() {
        if (!internal.securityCertificateDetails) {
            internal.securityCertificateDetails = PopupUtils.open(Qt.resolvedUrl("SecurityCertificatePopover.qml"), certificatePopoverPositioner, {"securityStatus": securityStatus})
        }
    }

    function hideSecurityCertificateDetails() {
        if (internal.securityCertificateDetails) {
            var popup = internal.securityCertificateDetails
            internal.securityCertificateDetails = null
            PopupUtils.close(popup)
        }
    }
}
