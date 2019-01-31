/*
 * Copyright 2015-2016 Canonical Ltd.
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
import ".."

Item {
    id: tabItem
    objectName: "tabItem"

    property bool incognito: false
    property bool active: false
    property bool hoverable: true
    property real rightMargin: 0

    property alias title: label.text
    property alias icon: favicon.source

    property real dragMin: 0
    property real dragMax: 0
    readonly property bool dragging: mouseArea.drag.active

    property color fgColor: theme.palette.normal.baseText

    property bool touchEnabled: true

    readonly property bool showCloseIcon: closeIcon.x > units.gu(1) + tabItem.width / 2

    signal selected()
    signal closed()
    signal contextMenu()

    Rectangle {
        id: tabImage
        anchors.fill: parent
        anchors.rightMargin: tabItem.rightMargin
        color: theme.palette.normal.background
        border.color: theme.palette.normal.base
        radius: units.gu(0.5)

        Favicon {
            id: favicon
            anchors {
                left: tabItem.showCloseIcon ? parent.left : undefined
                leftMargin: Math.min(tabItem.width / 4, units.gu(2))
                horizontalCenter: tabItem.showCloseIcon ? undefined : parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            shouldCache: !incognito

            // Scale width and height of favicon when tabWidth becomes small
            height: width
            width: Math.min(units.dp(16), Math.min(tabItem.width - anchors.leftMargin * 2, tabItem.height))
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
                color: tabItem.fgColor
            }

            Rectangle {
                anchors.centerIn: parent
                width: label.paintedHeight
                height: label.width + units.gu(0.25)
                rotation: 90
                gradient: Gradient {
                    GradientStop {
                        position: 0.0;
                        color: active ? theme.palette.normal.background :
                               (hoverArea.containsMouse ? theme.palette.normal.base : theme.palette.normal.foreground)
                    }
                    GradientStop { position: 0.33; color: "transparent" }
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: !tabItem.active && tabItem.hoverable
        }

        MouseArea {
            id: mouseArea
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            acceptedButtons: Qt.AllButtons
            onPressed: {
                if (mouse.button === Qt.LeftButton) {
                    tabItem.selected()
                } else if (mouse.button === Qt.RightButton) {
                    tabItem.contextMenu()
                }
            }
            onClicked: {
                if ((mouse.buttons === 0) && (mouse.button === Qt.MiddleButton)) {
                    tabItem.closed()
                }
            }
        }

        AbstractButton {
            id: closeButton
            objectName: "closeButton"

            // On touch the tap area to close the tab occupies the whole right
            // hand side of the tab, while it covers only the close icon in
            // other form factors
            anchors.fill: touchEnabled ? undefined : closeIcon
            anchors.top: touchEnabled ? parent.top : undefined
            anchors.bottom: touchEnabled ? parent.bottom : undefined
            anchors.right: touchEnabled ? parent.right : undefined
            width: touchEnabled ? units.gu(4) : closeIcon.width
            visible: closeIcon.visible

            onClicked: closed()

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                onClicked: closed()
            }
        }

        Icon {
            id: closeIcon
            height: units.gu(1.5)
            width: height
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1)
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            name: "close"
            color: tabItem.fgColor
            visible: tabItem.showCloseIcon
        }
    }
}
