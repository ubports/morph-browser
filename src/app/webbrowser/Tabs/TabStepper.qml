/*
 * Copyright (C) 2016 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Florian Boucault <florian.boucault@canonical.com>
 */
import QtQuick 2.4
import Ubuntu.Components 1.3

AbstractButton {
    id: stepper

    property color backgroundColor
    property color foregroundColor
    property color contourColor
    property color highlightColor
    property int counter
    property int layoutDirection: Qt.LeftToRight
    property bool active

    enabled: counter > 0
    opacity: active ? 1.0 : 0.0
    width: active ? row.width + row.anchors.leftMargin + row.anchors.rightMargin : 0
    Behavior on opacity {
        UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
    }
    Behavior on width {
        UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
    }
    activeFocusOnPress: false

    Timer {
        id: repeatClickTimer
        interval: 100
        running: stepper.pressed
        repeat: true
        onTriggered: stepper.clicked()
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        width: stepper.width
        color: stepper.highlightColor
        visible: stepper.pressed
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
        }
    }

    Row {
        id: row
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: units.gu(1)
        }
        spacing: units.gu(1)
        LayoutMirroring.enabled: stepper.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            source: Qt.resolvedUrl("tab_stepper.png")
            color: enabled ? stepper.foregroundColor : stepper.contourColor
            scale: LayoutMirroring.enabled ? -1.0 : 1.0
            asynchronous: true
            width: units.gu(1)
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            textSize: Label.Small
            text: stepper.counter
            color: enabled ? stepper.foregroundColor : stepper.contourColor
        }

        Item {
            width: 1
            height: 1
        }
    }
}
