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
import QtWebEngine 1.7
import ".."

FocusScope {
    id: root

    property var tab
    property alias loading: addressbar.loading
    property alias searchUrl: addressbar.searchUrl
    readonly property string text: addressbar.text
    property alias bookmarked: addressbar.bookmarked
    signal closeTabRequested()
    signal toggleBookmark()
    property list<Action> drawerActions
    readonly property bool drawerOpen: internal.openDrawer
    property alias requestedUrl: addressbar.requestedUrl
    property alias canSimplifyText: addressbar.canSimplifyText
    property alias findInPageMode: addressbar.findInPageMode
    property alias tabListMode: addressbar.tabListMode
    property alias contextMenuVisible: addressbar.contextMenuVisible
    property alias editing: addressbar.editing
    property alias incognito: addressbar.incognito
    property alias showFaviconInAddressBar: addressbar.showFavicon
    readonly property alias bookmarkTogglePlaceHolder: addressbar.bookmarkTogglePlaceHolder
    property color fgColor: theme.palette.normal.baseText
    property color iconColor: theme.palette.selected.base
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
            onTriggered: {
                if (findInPageMode) {
                    findInPageMode = false
                }
                else {
                    if (internal.webview.loading)
                    {
                        internal.webview.stop()
                    }
                    internal.webview.goBack()
                    }
                }
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
            onTriggered: {
                if (internal.webview.loading)
                {
                    internal.webview.stop()
                }
                internal.webview.goForward()
            }
        }

        AddressBar {
            id: addressbar

            fgColor: root.fgColor

            focus: true

            findInPageMode: findInPageMode
            findController: internal.webview ? internal.webview.findController : null
            certificateErrorsMap: internal.webview ? internal.webview.certificateErrorsMap : ({})
            lastLoadSucceeded: internal.webview ? internal.webview.lastLoadSucceeded : false

            anchors {
                left: parent.left
                // Work around https://launchpad.net/bugs/1546346 by ensuring
                // that the x coordinate of the text field is an integer.
                leftMargin: Math.round(backButton.width + forwardButton.width + units.gu(1))
                right: rightButtonsBar.left
                rightMargin: units.gu(1)
                top: parent.top
                bottom: parent.bottom
            }

            icon: (internal.webview && internal.webview.certificateError) ? "" : tab ? tab.icon : ""

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
                target: tab
                onUrlChanged: addressbar.actualUrl = tab.url
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
                enabled: internal.webview && internal.webview.findController && internal.webview.findController.foundMatch
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
                enabled: internal.webview && internal.webview.findController && internal.webview.findController.foundMatch
                onTriggered: internal.webview.findController.next()
            }

            ChromeButton {
                id: closeButton
                objectName: "closeButton"

                iconName: "close"
                iconSize: 0.3 * height
                iconColor: root.iconColor

                height: root.height
                width: height * 0.8

                anchors.verticalCenter: parent.verticalCenter

                visible: tabListMode

                onTriggered: closeTabRequested()
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
    }

    onTabChanged: {
        if (tab) {
            addressbar.actualUrl = tab.url
            if (!tab.url.toString() && editing) {
                addressbar.text = ""
            }
        } else {
            addressbar.actualUrl = ""
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
                anchors.fill: parent
                enabled: drawer.opened
                onPressed: drawer.opened = false
            }

            Rectangle {
                anchors.fill: actionsListView
                color: theme.palette.normal.background

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    width: units.dp(1)
                    color: theme.palette.normal.base
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: units.dp(1)
                    color: theme.palette.normal.background
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
                        color: theme.palette.selected.background
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
