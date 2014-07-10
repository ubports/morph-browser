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

import QtQuick 2.2
import Ubuntu.Components 0.1

FocusScope {
    id: chrome

    readonly property real visibleHeight: y + height
    property var webview
    property alias searchUrl: addressbar.searchUrl
    readonly property string text: addressbar.text

    signal validated()

    states: [
        State {
            name: "shown"
            PropertyChanges {
                target: chrome
                y: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: chrome
                y: -chrome.height
            }
        }
    ]
    state: "shown"

    Behavior on y {
        SmoothedAnimation {
            duration: UbuntuAnimation.BriskDuration
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    Item {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        focus: true

        readonly property real iconSize: 0.75 * height

        ChromeButton {
            id: backButton

            iconName: "back"
            iconSize: parent.iconSize

            height: parent.height
            width: height

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview.canGoBack
            onTriggered: chrome.webview.goBack()
        }

        ChromeButton {
            id: forwardButton

            iconName: "forward"
            iconSize: parent.iconSize

            height: parent.height
            visible: enabled
            width: visible ? height : 0

            anchors {
                left: backButton.right
                leftMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview.canGoForward
            onTriggered: chrome.webview.goForward()
        }

        AddressBar {
            id: addressbar

            focus: true

            anchors {
                left: forwardButton.right
                leftMargin: units.gu(1)
                right: drawerButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            onValidated: {
                chrome.webview.url = requestedUrl
                chrome.webview.forceActiveFocus()
            }
            onRequestReload: chrome.webview.reload()
            onRequestStop: chrome.webview.stop()

            Connections {
                target: chrome.webview
                onUrlChanged: {
                    // ensure that the URL actually changes so that the
                    // address bar is updated in case the user has entered a
                    // new address that redirects to where she previously was
                    // (https://bugs.launchpad.net/webbrowser-app/+bug/1306615)
                    addressbar.actualUrl = ""
                    addressbar.actualUrl = chrome.webview.url
                }
            }
        }

        ChromeButton {
            id: drawerButton

            iconName: "contextual-menu"
            iconSize: parent.iconSize

            height: parent.height
            width: height

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            onTriggered: console.log("TODO: show/hide drawer")
        }
    }

    onWebviewChanged: {
        if (webview) {
            addressbar.actualUrl = webview.url
        }
    }

    ProgressBar {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.dp(3)
        value: chrome.webview ? chrome.webview.loadProgress / 100 : 0.0
        visible: chrome.webview ? chrome.webview.loading
                                  // workaround for https://bugs.launchpad.net/oxide/+bug/1290821
                                  && !webview.lastLoadStopped
                                : false
    }
}

