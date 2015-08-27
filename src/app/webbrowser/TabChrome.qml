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

    signal selected()
    signal closed()

    implicitHeight: units.gu(4)

    BorderImage {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.5
        source: 'assets/tab-%1.sci'.arg(hoverArea.containsMouse ? 'hover' :
                                        (active ? 'active' : 'non-active'))

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
            }

            Rectangle {
                anchors.centerIn: parent
                width: label.paintedHeight
                height: label.width + units.gu(0.25)
                rotation: 90
                gradient: Gradient {
                    GradientStop {
                        position: 0.0;
                        color: (hoverArea.containsMouse) ? "#f1f1f1" :
                               ((active) ? "#f8f8f8" : "#ebebeb")
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

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
