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

Column {
    id: tab

    property alias title: label.text
    property var webview

    signal selected()
    signal closeRequested()

    Rectangle {
        id: header

        width: parent.width
        height: units.gu(4)
        color: "white"

        Row {
            anchors.fill: parent
            spacing: units.gu(1)

            AbstractButton {
                id: closeButton

                height: parent.height
                width: units.gu(6)

                Icon {
                    height: units.gu(3)
                    width: height
                    anchors.centerIn: parent
                    name: "close"
                }

                onTriggered: tab.closeRequested()
            }

            Label {
                id: label
                width: parent.width - closeButton.width
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Item {
        // inactive webview / image

        width: parent.width
        height: parent.height - header.height

        // XXX: temporary placeholder
        Rectangle {
            color: "red"
            opacity: 0.4
            anchors.fill: parent
        }

        MouseArea {
            anchors.fill: parent
            onClicked: tab.selected()
        }
    }
}
