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

import QtQuick 2.2
import Ubuntu.Components 0.1

FocusScope {
    id: chrome

    readonly property real visibleHeight: y + height
    property var webview

    states: [
        State {
            name: "shown"
        },
        State {
            name: "hidden"
        }
    ]
    state: "shown"

    y: (state == "shown") ? 0 : -height
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

    ThinProgressBar {
        webview: chrome.webview

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }
}
