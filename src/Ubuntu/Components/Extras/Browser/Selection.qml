/*
 * Copyright 2013 Canonical Ltd.
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

Item {
    id: __container

    property alias rect: __rect

    property real __minimumWidth: units.gu(5)
    property real __minimumHeight: units.gu(5)

    signal resized()

    MouseArea {
        anchors.fill: parent
        // dismiss the selection when tapping anywhere except for the handles
        onClicked: __container.visible = false
    }

    Item {
        id: __rect
    }

    Rectangle {
        id: __outline

        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: parent.border.color
            opacity: 0.1
            z: -1
        }

        border {
            width: units.dp(3)
            color: "#19B6EE"
        }
        radius: units.dp(3)
        antialiasing: true

        x: __rect.x
        width: {
            if (__leftHandle.dragging) {
                return __rect.x + __rect.width - (__leftHandle.x + __leftHandle.width / 2)
            } else if (__rightHandle.dragging) {
                return __rightHandle.x + __rightHandle.width / 2 - __rect.x
            } else {
                return __rect.width
            }
        }

        y: __rect.y
        height: {
            if (__topHandle.dragging) {
                return __rect.y + __rect.height - (__topHandle.y + __topHandle.height / 2)
            } else if (__bottomHandle.dragging) {
                return __bottomHandle.y + __bottomHandle.height / 2 - __rect.y
            } else {
                return __rect.height
            }
        }

        anchors {
            left: __rightHandle.dragging ? __rect.left: undefined
            right: __leftHandle.dragging ? __rect.right : undefined
            top: __bottomHandle.dragging ? __rect.top : undefined
            bottom: __topHandle.dragging ? __rect.bottom : undefined
        }
    }

    SelectionHandle {
        id: __leftHandle
        axis: Drag.XAxis
        x: __rect.x - width / 2
        y: (__topHandle.y + __bottomHandle.y) / 2
        minimum: 0
        maximum: __rightHandle.x - __container.__minimumWidth
        onDraggingChanged: {
            if (!dragging) {
                __rect.width = __rightHandle.x - __leftHandle.x
                __rect.x = __leftHandle.x + __leftHandle.width / 2
                __container.resized()
            }
        }
    }

    SelectionHandle {
        id: __topHandle
        axis: Drag.YAxis
        x: (__leftHandle.x + __rightHandle.x) / 2
        y: __rect.y - height / 2
        minimum: 0
        maximum: __bottomHandle.y - __container.__minimumHeight
        onDraggingChanged: {
            if (!dragging) {
                __rect.height = __bottomHandle.y - __topHandle.y
                __rect.y = __topHandle.y + __topHandle.height / 2
                __container.resized()
            }
        }
    }

    SelectionHandle {
        id: __rightHandle
        axis: Drag.XAxis
        x: __rect.x + __rect.width - width / 2
        y: (__topHandle.y + __bottomHandle.y) / 2
        minimum: __leftHandle.x + __container.__minimumWidth
        maximum: __container.width
        onDraggingChanged: {
            if (!dragging) {
                __rect.width = __rightHandle.x - __leftHandle.x
                __container.resized()
            }
        }
    }

    SelectionHandle {
        id: __bottomHandle
        axis: Drag.YAxis
        x: (__leftHandle.x + __rightHandle.x) / 2
        y: __rect.y + __rect.height - height / 2
        minimum: __topHandle.y + __container.__minimumHeight
        maximum: __container.height
        onDraggingChanged: {
            if (!dragging) {
                __rect.height = __bottomHandle.y - __topHandle.y
                __container.resized()
            }
        }
    }
}
