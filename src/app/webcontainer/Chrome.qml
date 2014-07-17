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
import ".."

FocusScope {
    id: chrome

    readonly property real visibleHeight: y + height
    property var webview
    //property list<Action> drawerActions
    property bool navigationButtonsVisible: false

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
        color: "#ededef"

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)
            color: UbuntuColors.warmGrey
        }
    }

    FocusScope {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        focus: true

        readonly property real iconSize: 0.75 * height

        ChromeButton {
            id: backButton
            objectName: "backButton"

            iconName: "previous"
            iconSize: parent.iconSize

            height: parent.height
            visible: chrome.navigationButtonsVisible
            width: visible ? height : 0

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoBack : false
            onTriggered: chrome.webview.goBack()
        }

        ChromeButton {
            id: forwardButton
            objectName: "forwardButton"

            iconName: "next"
            iconSize: parent.iconSize

            height: parent.height
            visible: chrome.navigationButtonsVisible && enabled
            width: visible ? height : 0

            anchors {
                left: backButton.right
                leftMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoForward : false
            onTriggered: chrome.webview.goForward()
        }

        Item {
            id: faviconContainer

            height: parent.height
            width: height
            anchors.left: forwardButton.right

            Favicon {
                id: favicon
                anchors.centerIn: parent
                visible: status == Image.Ready
            }

            Icon {
                anchors.fill: favicon
                name: "stock_website"
                visible: !favicon.visible
            }
        }

        Label {
            anchors {
                left: faviconContainer.right
                right: parent.right
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            text: chrome.webview.title ? chrome.webview.title : chrome.webview.url
            elide: Text.ElideRight
        }
    }

    ThinProgressBar {
        webview: chrome.webview

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
