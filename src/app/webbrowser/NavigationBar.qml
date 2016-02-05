/*
 * Copyright 2013-2016 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import ".."

FocusScope {
    id: root

    property var tab
    property alias searchUrl: addressbar.searchUrl
    readonly property string text: addressbar.text
    property alias bookmarked: addressbar.bookmarked
    signal toggleBookmark()
    property list<Action> drawerActions
    readonly property bool drawerOpen: internal.openDrawer
    property alias requestedUrl: addressbar.requestedUrl
    property alias canSimplifyText: addressbar.canSimplifyText
    property alias findInPageMode: addressbar.findInPageMode
    property alias editing: addressbar.editing
    property alias incognito: addressbar.incognito
    property alias showFaviconInAddressBar: addressbar.showFavicon
    readonly property alias bookmarkTogglePlaceHolder: addressbar.bookmarkTogglePlaceHolder
    property color fgColor: Theme.palette.normal.baseText
    property color iconColor: UbuntuColors.darkGrey
    property real availableHeight

    onFindInPageModeChanged: if (findInPageMode) addressbar.text = ""
    onIncognitoChanged: findInPageMode = false

    function selectAll() {
        addressbar.selectAll()
    }

    FocusScope {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        focus: true

        ChromeButton {
            id: backButton
            objectName: "backButton"

            iconName: "previous"
            iconSize: 0.4 * height
            iconColor: root.iconColor

            height: root.height
            width: height * 0.8

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            enabled: findInPageMode || (internal.webview ? internal.webview.canGoBack : false)
            onTriggered: findInPageMode ? (findInPageMode = false) : internal.webview.goBack()
        }

        ChromeButton {
            id: forwardButton
            objectName: "forwardButton"

            iconName: "next"
            iconSize: 0.4 * height
            iconColor: root.iconColor

            height: root.height
            visible: enabled
            width: visible ? height * 0.8 : 0

            anchors {
                left: backButton.right
                verticalCenter: parent.verticalCenter
            }

            enabled: findInPageMode ? false :
                     (internal.webview ? internal.webview.canGoForward : false)
            onTriggered: internal.webview.goForward()
        }

        AddressBar {
            id: addressbar

            fgColor: root.fgColor

            focus: true

            findInPageMode: findInPageMode
            findController: internal.webview ? internal.webview.findController : null

            anchors {
                left: forwardButton.right
                leftMargin: units.gu(1)
                right: rightButtonsBar.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            icon: (internal.webview && internal.webview.certificateError) ? "" : tab ? tab.icon : ""

            loading: internal.webview ? internal.webview.loading : false

            onValidated: {
                if (!findInPageMode) {
                    internal.webview.forceActiveFocus()
                    internal.webview.url = requestedUrl
                }
            }
            onRequestReload: {
                internal.webview.forceActiveFocus()
                internal.webview.reload()
            }
            onRequestStop: internal.webview.stop()
            onToggleBookmark: root.toggleBookmark()

            Connections {
                target: internal.webview
                onUrlChanged: {
                    // ensure that the URL actually changes so that the
                    // address bar is updated in case the user has entered a
                    // new address that redirects to where she previously was
                    // (https://launchpad.net/bugs/1306615)
                    addressbar.actualUrl = ""
                    addressbar.actualUrl = internal.webview.url
                }
            }
        }

        Row {
            id: rightButtonsBar

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            ChromeButton {
                id: findPreviousButton
                objectName: "findPreviousButton"

                iconName: "up"
                iconSize: 0.5 * height

                height: root.height
                width: height * 0.8

                anchors.verticalCenter: parent.verticalCenter

                visible: findInPageMode
                enabled: internal.webview && internal.webview.findController &&
                         internal.webview.findController.count > 1
                onTriggered: internal.webview.findController.previous()
            }

            ChromeButton {
                id: findNextButton
                objectName: "findNextButton"

                iconName: "down"
                iconSize: 0.5 * height

                height: root.height
                width: height * 0.8

                anchors.verticalCenter: parent.verticalCenter

                visible: findInPageMode
                enabled: internal.webview && internal.webview.findController &&
                         internal.webview.findController.count > 1
                onTriggered: internal.webview.findController.next()
            }

            ChromeButton {
                id: drawerButton
                objectName: "drawerButton"

                iconName: "contextual-menu"
                iconSize: 0.5 * height
                iconColor: root.iconColor

                height: root.height
                width: height * 0.8

                anchors.verticalCenter: parent.verticalCenter

                onTriggered: {
                    if (!internal.openDrawer) {
                        internal.openDrawer = drawerComponent.createObject(chrome)
                        internal.openDrawer.opened = true
                    }
                }
            }
        }
    }

    QtObject {
        id: internal
        property var openDrawer: null
        readonly property var webview: tab ? tab.webview : null

        onWebviewChanged: {
            if (webview) {
                addressbar.actualUrl = webview.url
                addressbar.securityStatus = webview.securityStatus
            } else {
                addressbar.actualUrl = ""
                addressbar.securityStatus = null
            }
        }
    }

    Component {
        id: drawerComponent

        Item {
            id: drawer
            objectName: "drawer"

            property bool opened: false
            property bool closing: false
            onOpenedChanged: {
                if (!opened) {
                    closing = true
                }
            }

            anchors {
                top: parent.bottom
                right: parent.right
            }
            width: units.gu(22)
            height: actionsListView.height
            clip: actionsListView.y != 0

            InverseMouseArea {
                enabled: drawer.opened
                onPressed: drawer.opened = false
            }

            Rectangle {
                anchors.fill: actionsListView
                color: Theme.palette.normal.background

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    width: units.dp(1)
                    color: "#dedede"
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: units.dp(1)
                    color: "#dedede"
                }
            }

            ListView {
                id: actionsListView

                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: Math.min(_contentHeight, availableHeight)
                // avoid a binding loop
                property real _contentHeight: 0
                onContentHeightChanged: _contentHeight = contentHeight

                y: drawer.opened ? 0 : -height
                Behavior on y { UbuntuNumberAnimation {} }
                onYChanged: {
                    if (drawer.closing && (y == -height)) {
                        drawer.destroy()
                    }
                }

                clip: true

                model: drawerActions

                delegate: AbstractButton {
                    objectName: action.objectName
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: visible ? units.gu(6) : 0
                    visible: action.enabled

                    action: modelData
                    onClicked: drawer.opened = false

                    Rectangle {
                        anchors.fill: parent
                        color: Theme.palette.selected.background
                        visible: parent.pressed
                    }

                    Icon {
                        id: actionIcon
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        width: units.gu(2)
                        height: width

                        name: model.iconName
                        Binding on source {
                            when: model.iconSource.toString()
                            value: model.iconSource
                        }
                        color: root.fgColor
                    }

                    Label {
                        anchors {
                            left: actionIcon.right
                            leftMargin: units.gu(2)
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: units.gu(1)
                        }
                        text: model.text
                        fontSize: "small"
                        color: root.fgColor
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
