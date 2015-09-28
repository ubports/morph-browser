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
import ".."

Item {
    id: tabItem

    property bool incognito: false
    property bool active: false
    property bool hoverable: true
    property int rightMargin: tabImage.anchors.rightMargin

    property alias title: label.text
    property alias icon: favicon.source

    signal selected()
    signal closed()

    BorderImage {
        id: tabImage
        anchors.fill: parent
        anchors.rightMargin: tabItem.rightMargin
        source: "assets/tab-%1%2.sci".arg((active) ? "active" :
                                          (hoverArea.containsMouse ? "hover" : "non-active"))
                                     .arg(formFactor == "desktop" ? "-desktop" : "")

        Favicon {
            id: favicon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
            shouldCache: !incognito
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
                        color: active ? "#f8f8f8" :
                               (hoverArea.containsMouse ? "#cecece" : "#dedede")
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
            onClicked: tabItem.selected()
        }

        AbstractButton {
            id: closeButton
            objectName: "closeButton"

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: formFactor == "mobile" ? units.gu(4) : units.gu(2)

            Icon {
                height: units.gu(1.5)
                width: height
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1)
                anchors.verticalCenter: parent.verticalCenter
                name: "close"
            }

            onTriggered: closed()
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: !tabItem.active && tabItem.hoverable
            propagateComposedEvents: true
            acceptedButtons: Qt.MiddleButton
            onClicked: tabItem.closed()
        }
    }
}

