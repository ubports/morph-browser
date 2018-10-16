/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import ".."
import "../UrlUtils.js" as UrlUtils

FocusScope {
    id: addressbar

    property alias icon: favicon.source
    property bool incognito: false
    property alias text: textField.text
    property bool bookmarked: false
    signal toggleBookmark()
    property url requestedUrl
    property url actualUrl
    signal validated()
    property bool loading
    signal requestReload()
    signal requestStop()
    property string searchUrl
    property bool canSimplifyText: true
    property bool editing: false
    property bool showFavicon: true
    property bool findInPageMode: false
    property var findController: null
    property color fgColor: Theme.palette.normal.baseText

    property var securityStatus: null

    readonly property Item bookmarkTogglePlaceHolder: bookmarkTogglePlaceHolderItem

    // XXX: for testing purposes only, do not use to modify the
    // contents/behaviour of the internals of the component.
    readonly property Item __textField: textField
    readonly property Item __actionButton: action
    readonly property Item __bookmarkToggle: bookmarkToggle

    function selectAll() {
        textField.selectAll()
    }

    Binding {
        //target: findController
        property: "text"
        value: findInPageMode ? textField.text : ""
    }

    TextField {
        id: textField
        objectName: "addressBarTextField"

        anchors.fill: parent

        primaryItem: Item {
            id: icons

            width: iconsRow.anyIconVisible ? iconsRow.width + units.gu(1) : 0
            height: units.gu(2)
            visible: !findInPageMode

            Row {
                id: iconsRow
                property bool anyIconVisible: favicon.visible || action.visible ||
                                              secure.visible || insecure.visible ||
                                              securityAlert.visible
                spacing: units.gu(1)
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                Favicon {
                    id: favicon
                    shouldCache: !addressbar.incognito
                    anchors.verticalCenter: parent.verticalCenter
                    visible: showFavicon && internal.idle && addressbar.actualUrl.toString() &&
                             !internal.securityWarning && !internal.securityError
                }

                Icon {
                    id: action

                    height: parent.height
                    width: height

                    visible: addressbar.editing || addressbar.loading || !addressbar.text

                    enabled: addressbar.text
                    opacity: enabled ? 1.0 : 0.3
                    asynchronous: true

                    readonly property bool reload: addressbar.activeFocus && addressbar.text &&
                                                   (addressbar.text == addressbar.actualUrl)
                    readonly property bool looksLikeAUrl: UrlUtils.looksLikeAUrl(addressbar.text.trim())

                    name: addressbar.loading ? "stop" :
                          reload ? "reload" :
                          looksLikeAUrl ? "stock_website" : "search"
                    color: addressbar.fgColor

                    MouseArea {
                        objectName: "actionButton"

                        anchors {
                            fill: parent
                            margins: -units.gu(1)
                        }

                        onClicked: {
                            if (addressbar.loading) {
                                addressbar.requestStop()
                            } else if (action.reload) {
                                addressbar.requestReload()
                            } else {
                                textField.accepted()
                            }
                        }
                    }
                }

                Icon {
                    id: secure
                    name: "network-secure"
                    color: addressbar.fgColor
                    height: parent.height
                    width: height
                    visible: internal.idle && internal.secureConnection
                    asynchronous: true
                }

                Image {
                    id: insecure
                    source: "assets/broken_lock.png"
                    height: parent.height
                    fillMode: Image.PreserveAspectFit
                    visible: internal.idle && internal.securityError
                    asynchronous: true
                }

                Icon {
                    id: securityAlert
                    name: "security-alert"
                    color: addressbar.fgColor
                    height: parent.height
                    width: height
                    visible: internal.idle && internal.securityWarning
                    asynchronous: true
                }
            }

            Item {
                id: certificatePopoverPositioner
                anchors {
                    top: iconsRow.top
                    bottom: iconsRow.bottom
                    left: iconsRow.left
                }
                width: units.gu(2)
            }

            MouseArea {
                enabled: internal.idle
                anchors {
                    left: iconsRow.left
                    leftMargin: -units.gu(1)
                    right: iconsRow.right
                    verticalCenter: parent.verticalCenter
                }
                height: textField.height

                onClicked: {
                    if (internal.secureConnection || internal.securityError) {
                        addressbar.showSecurityCertificateDetails()
                    }
                }
            }
        }

        secondaryItem: Row {
            height: textField.height

            Label {
                objectName: "findInPageCounter"
                anchors.verticalCenter: parent.verticalCenter
                fontSize: "x-small"
                color: addressbar.fgColor
                opacity: findController && findController.count > 0 ? 1.0 : 0.6
                visible: findInPageMode

                // TRANSLATORS: %2 refers to the total number of find in page results and %1 to the highlighted result
                text: i18n.tr("%1/%2").arg(current).arg(count)
                property int current: findController ? findController.current : 0
                property int count: findController ? findController.count : 0
            }

            MouseArea {
                id: bookmarkToggle
                objectName: "bookmarkToggle"

                height: parent.height
                width: visible ? height : 0

                visible: !findInPageMode && internal.idle && addressbar.actualUrl.toString()

                Icon {
                    height: parent.height - units.gu(2)
                    width: height
                    anchors.centerIn: parent

                    name: addressbar.bookmarked ? "starred" : "non-starred"
                    color: addressbar.bookmarked ? UbuntuColors.orange : addressbar.fgColor
                }

                onClicked: addressbar.toggleBookmark()

                Item {
                    id: bookmarkTogglePlaceHolderItem
                    anchors.fill: parent
                }
            }
        }

        font.pixelSize: FontUtils.sizeToPixels("small")
        color: addressbar.fgColor
        inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText

        placeholderText: findInPageMode ? i18n.tr("find in page")
                                        : i18n.tr("search or enter an address")

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

        onAccepted: if (!internal.idle) internal.validate()

        Keys.onReturnPressed: {
            if (!findInPageMode) {
                accepted()
            } else if (event.modifiers & Qt.ShiftModifier) {
                findController.previous()
            } else {
                findController.next()
            }
        }
    }

    // Make sure that all the text is selected at the first click
    MouseArea {
        anchors {
            fill: parent
            leftMargin: icons.width
            rightMargin: bookmarkToggle.width
        }

        enabled: !addressbar.activeFocus
        onClicked: {
            textField.forceActiveFocus()
            textField.selectAll()
        }
    }

    QtObject {
        id: internal

        readonly property bool idle: !addressbar.loading && !addressbar.editing

        readonly property int securityLevel: 0 //addressbar.securityStatus ? addressbar.securityStatus.securityLevel : Oxide.SecurityStatus.SecurityLevelNone
        readonly property bool secureConnection: true //addressbar.securityStatus ? (securityLevel == Oxide.SecurityStatus.SecurityLevelSecure || securityLevel == Oxide.SecurityStatus.SecurityLevelSecureEV || securityLevel == Oxide.SecurityStatus.SecurityLevelWarning) : false
        readonly property bool securityWarning: false //addressbar.securityStatus ? (securityLevel == Oxide.SecurityStatus.SecurityLevelWarning) : false
        readonly property bool securityError: false //addressbar.securityStatus ? (securityLevel == Oxide.SecurityStatus.SecurityLevelError) : false

        property var securityCertificateDetails: null

        function escapeHtmlEntities(query) {
            return query.replace(/\W/g, encodeURIComponent)
        }

        function buildSearchUrl(query) {
            var terms = query.split(/\s/).map(internal.escapeHtmlEntities)
            return addressbar.searchUrl.replace("{searchTerms}", terms.join("+"))
        }

        function validate() {
            var query = text.trim()
            if (UrlUtils.looksLikeAUrl(query)) {
                requestedUrl = UrlUtils.fixUrl(query)
            } else {
                requestedUrl = internal.buildSearchUrl(query)
            }
            validated()
        }

        function simplifyUrl(url) {
            var urlString = url.toString()
            if (urlString == "about:blank" || urlString.match(/^data:/i)) {
                return url
            }
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

        // has the URL in the address bar been simplified?
        property bool simplified: false
    }

    onIncognitoChanged: {
        if (incognito) {
            text = ""
            internal.simplified = false
        }
    }

    onEditingChanged: {
        if (findInPageMode) return
        if (editing && internal.simplified) {
            text = actualUrl
            internal.simplified = false
        } else if (!editing) {
            if (canSimplifyText && !loading && actualUrl.toString()) {
                text = internal.simplifyUrl(actualUrl)
                internal.simplified = true
            } else {
                text = actualUrl
                internal.simplified = false
            }
        }
    }

    onCanSimplifyTextChanged: {
        if (editing || findInPageMode) return
        if (canSimplifyText && !loading && actualUrl.toString()) {
            text = internal.simplifyUrl(actualUrl)
            internal.simplified = true
        } else if (!canSimplifyText && internal.simplified) {
            text = actualUrl
            internal.simplified = false
        }
    }

    onActualUrlChanged: {
        if (editing || findInPageMode) return
        if (canSimplifyText) {
            text = internal.simplifyUrl(actualUrl)
            internal.simplified = true
        } else {
            text = actualUrl
            internal.simplified = false
        }
    }

    onRequestedUrlChanged: {
        if (editing || findInPageMode) return
        if (canSimplifyText) {
            text = internal.simplifyUrl(requestedUrl)
            internal.simplified = true
        } else {
            text = requestedUrl
            internal.simplified = false
        }
    }

    onFindInPageModeChanged: {
        if (findInPageMode) return
        if (canSimplifyText) {
            text = internal.simplifyUrl(actualUrl)
            internal.simplified = true
        } else {
            text = actualUrl
            internal.simplified = false
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
