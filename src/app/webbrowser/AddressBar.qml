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
import Ubuntu.Components.ListItems 1.0
import com.canonical.Oxide 1.0 as Oxide
import ".."

FocusScope {
    id: addressbar

    property alias icon: favicon.source
    property alias text: textField.text
    property bool bookmarked: false
    property url requestedUrl
    property url actualUrl
    property var securityStatus
    signal validated()
    property bool loading
    signal requestReload()
    signal requestStop()
    signal pressAndHold()
    property string searchUrl

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
            width: iconsRow.width
            height: iconsRow.height
            Row {
                id: iconsRow
                Item {
                    height: textField.height
                    width: height
    
                    Favicon {
                        id: favicon
                        anchors.centerIn: parent
                        visible: (addressbar.state == "") && addressbar.actualUrl.toString()
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
    
                Item {
                    id: securityDisplay
                    height: textField.height
                    width: securityIcon.width
                    visible: securityStatus ? (securityStatus.securityLevel == Oxide.SecurityStatus.SecurityLevelSecure || securityStatus.securityLevel == Oxide.SecurityStatus.SecurityLevelSecureEV) : false
    
                    Icon {
                        id: securityIcon
                        anchors.centerIn: parent
                        height: parent.height - units.gu(2)
                        width: height
                        name: "network-secure"
                    }
                }

            }

            MouseArea {
                enabled: securityDisplay.visible && addressbar.state != "editing" && addressbar.state != "loading"
                anchors.fill: parent

                onClicked: {
                    PopupUtils.open(certificatePopover, certificatePopoverPositioner)
                }
            }


            Component {
                id: certificatePopover
                Popover {
                    Column {
                        id: certificateDetails 
                        width: parent.width - units.gu(4)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(0.5)

                        Item {
                            height: units.gu(1.5)
                            width: parent.width
                        }

                        Label { 
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: i18n.tr("You are connected to")
                            fontSize: "x-small"
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: securityStatus.certificate.subjectDisplayName
                            fontSize: "x-small"
                        }

                        ThinDivider { width: parent.width }

                        Item {
                            height: units.gu(0.5)
                            width: parent.width
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: i18n.tr("Which is run by")
                            fontSize: "x-small"
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrOrganizationName).join(", ")
                            fontSize: "x-small"
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrLocalityName).join(", ")
                            fontSize: "x-small"
                        }

                        Label {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrStateOrProvinceName).join(", ") + ", " + securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrCountryName).join(", ")
                            fontSize: "x-small"
                        }

                        Item {
                            height: units.gu(1.5)
                            width: parent.width
                        }

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

        function ensureSchemeVisibleWhenUnfocused() {
            // Ensure the beginning of the URL is always visible when unfocused.
            // In the future, we’ll have a smarter address bar that hides the
            // scheme to save some extra space and display more of the
            // meaningful part of the URL (domain name and path).
            if (!activeFocus) {
                cursorPosition = 0
            }
        }
        onActiveFocusChanged: {
            if (!activeFocus) {
                if (!addressbar.loading && addressbar.actualUrl.toString()) {
                    text = addressbar.actualUrl
                }
            }
            ensureSchemeVisibleWhenUnfocused()
        }
        onTextChanged: ensureSchemeVisibleWhenUnfocused()

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

    onActualUrlChanged: text = actualUrl
}
