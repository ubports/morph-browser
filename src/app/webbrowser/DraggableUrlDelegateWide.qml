/*
 * Copyright 2015 Canonical Ltd.
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

UrlDelegateWide {
    id: item

    z: Drag.active ? 1 : 0 // display on top of siblings while dragging
    Drag.active: gripArea.drag.active
    Drag.hotSpot.x: grip.x
    Drag.hotSpot.y: grip.y
    Drag.onActiveChanged: {
        if (item.Drag.active) {
            internal.positionBeforeDrag = Qt.point(x, y)
            item.dragStarted()
        }
    }

    property bool draggable: true
    property int gripMargin: units.gu(1)
    signal dragStarted()
    signal dragEnded(var dragAndDrop)

    // only monitors hover events without capturing any click or drag
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

    Icon {
        id: grip
        objectName: "dragGrip"

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: item.gripMargin

        width: units.gu(3)
        height: width
        name: "view-grid-symbolic"

        opacity: item.draggable && hoverArea.containsMouse ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: UbuntuAnimation.SnapDuration
                easing: UbuntuAnimation.StandardEasing
            }
        }

        MouseArea {
            id: gripArea
            anchors.fill: parent
            drag.target: item.draggable ? item : null
            onReleased: {
                var result = { success: false, target: item.Drag.target }
                item.dragEnded(result)
                if (result.success) item.Drag.drop()
                else {
                    item.x = internal.positionBeforeDrag.x
                    item.y = internal.positionBeforeDrag.y
                    item.Drag.cancel()
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: theme.palette.normal.base
        border.width: 1
        visible: item.Drag.active
    }

    QtObject {
        id: internal
        property point positionBeforeDrag
    }
}
