/*
 * Copyright 2014-2015 Canonical Ltd.
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

Item {
    id: tabChrome
    property alias title: label.text
    property alias icon: favicon.source
    property bool incognito: false
    property bool active: false
    property alias tabWidth: tabItem.width

    signal selected()
    signal closed()

    Item {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(5)
        clip: true

        BorderImage {
            // We are basically splitting the shadow asset in two parts.
            // The left side is never scaled and it stays fixed below the
            // tab itself (with 4dp of the shadow poking out at the sides).
            // The right side will scale across the remaining width of the
            // component (which is empty and lets the previous preview show
            // through)
            border {
                left: tabWidth + units.dp(4)
            }
            anchors.fill: parent
            anchors.bottomMargin: - units.gu(3)
            height: units.gu(8)
            source: "assets/tab-shadow-narrow.png"
            opacity: 0.5
        }
    }

    BorderImage {
        id: tabItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        source: 'assets/tab-non-active.sci'

        Favicon {
            id: favicon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            width: units.gu(2)
            height: width

            shouldCache: !tabChrome.incognito
        }

        Item {
            anchors.left: favicon.right
            anchors.leftMargin: units.gu(1)
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: closeButton.left
            anchors.rightMargin: units.gu(1)

            Label {
                id: label
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                clip: true
                fontSize: "small"
            }

            Rectangle {
                anchors.centerIn: parent
                width: label.paintedHeight
                height: label.width + units.gu(0.25)
                rotation: 90
                gradient: Gradient {
                    GradientStop {
                        position: 0.0;
                        color: "#ebebeb"
                    }
                    GradientStop { position: 0.33; color: "transparent" }
                }
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: closeButton.left
            onClicked: selected()
        }

        AbstractButton {
            id: closeButton
            objectName: "closeButton"

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: units.gu(4)

            Icon {
                height: units.gu(1.5)
                width: height
                anchors.centerIn: parent
                name: "close"
            }

            onTriggered: closed()
        }
    }
}
