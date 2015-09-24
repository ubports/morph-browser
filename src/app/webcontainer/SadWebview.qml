/*
 * Copyright 2015 Canonical Ltd.
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
import com.canonical.Oxide 1.8 as Oxide
import ".."

Rectangle {
    property var webview

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (webview) {
                spinner.running = true
                webview.reload()
            }
        }
    }

    Column {
        anchors {
            fill: parent
            margins: units.gu(4)
        }
        spacing: units.gu(4)

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "../assets/tab-error.png"
        }

        ActivityIndicator {
            id: spinner
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
