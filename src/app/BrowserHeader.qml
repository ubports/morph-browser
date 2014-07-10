/*
 * Copyright 2014 Canonical Ltd.
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

// XXX: Temporary implementation for testing purposes
FocusScope {
    id: header

    readonly property real visibleHeight: y + height
    property var webview
    property alias searchUrl: addressbar.searchUrl
    readonly property string text: addressbar.text

    signal validated()

    states: [
        State {
            name: "shown"
            PropertyChanges {
                target: header
                y: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: header
                y: -header.height
            }
        }
    ]
    state: "shown"

    Behavior on y {
        NumberAnimation { duration: UbuntuAnimation.FastDuration }
    }

    Rectangle {
        anchors.fill: parent
        color: "lightsteelblue"
    }

    AddressBar {
        id: addressbar

        focus: true

        anchors {
            left: parent.left
            leftMargin: units.gu(1)
            right: parent.right
            rightMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }

        onValidated: {
            header.webview.url = requestedUrl
            header.webview.forceActiveFocus()
        }
        onRequestReload: header.webview.reload()
        onRequestStop: header.webview.stop()

        Connections {
            target: header.webview
            onUrlChanged: {
                // ensure that the URL actually changes so that the
                // address bar is updated in case the user has entered a
                // new address that redirects to where she previously was
                // (https://bugs.launchpad.net/webbrowser-app/+bug/1306615)
                addressbar.actualUrl = ""
                addressbar.actualUrl = header.webview.url
            }
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
        value: header.webview ? header.webview.loadProgress / 100 : 0.0
        visible: header.webview ? header.webview.loading
                                  // workaround for https://bugs.launchpad.net/oxide/+bug/1290821
                                  && !webview.lastLoadStopped
                                : false
    }
}
