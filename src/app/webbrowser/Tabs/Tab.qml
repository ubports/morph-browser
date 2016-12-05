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
 *              Andrew Hayzen <andrew.hayzen@canonical.com>
 */
import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: tab

    property color backgroundColor: "white"
    property color foregroundColor: "black"
    property color contourColor
    property color actionColor
    property color highlightColor
    property string title
    property bool isFocused
    property bool isBeforeFocusedTab
    property bool isHovered: false
    property string iconName: ""
    property url iconSource: ""
    property string fallbackIcon: ""
    signal close

    implicitHeight: units.gu(3)
    implicitWidth: units.gu(27)

    Rectangle {
        id: hoverFeedback
        anchors {
            fill: parent
            leftMargin: -tabSeparator.width
        }
        color: tab.highlightColor
        visible: tab.isHovered && !tab.isFocused
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
        }
    }

    TabContour {
        anchors {
            fill: parent
            topMargin: units.dp(2)
        }
        visible: tab.isFocused
        backgroundColor: tab.backgroundColor
        contourColor: tab.contourColor
    }

    Rectangle {
        id: tabSeparator
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        width: units.dp(1)
        height: units.gu(2)
        color: tab.contourColor
        visible: !tab.isFocused && !tab.isBeforeFocusedTab
    }

    MouseArea {
        id: tabCloseButton
        objectName: "tabCloseButton"

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(3)
        hoverEnabled: true
        onClicked: tab.close()

        Rectangle {
            anchors.centerIn: parent
            property real size: units.gu(2)
            width: size
            height: size
            radius: size
            color: tab.highlightColor
            visible: tabCloseButton.containsMouse || tabCloseButton.pressed
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                UbuntuNumberAnimation { duration: UbuntuAnimation.FastDuration }
            }
        }

        Icon {
            width: units.gu(1)
            height: width
            anchors.centerIn: parent
            asynchronous: true
            name: "close"
            color: tab.actionColor
        }
    }

    Loader {
        id: iconContainer
        active: iconName !== "" || iconSource.toString() !== "" || fallbackIcon !== ""
        anchors {
            left: tabCloseButton.right
            verticalCenter: parent.verticalCenter
        }
        asynchronous: true
        height: parent.height - units.gu(1)
        width: height
        visible: status === Loader.Ready

        Component.onCompleted: {
            setSource(
                Qt.resolvedUrl("TabIcon.qml"),
                {
                    "iconName": Qt.binding(function() { return iconName; }),
                    "iconSource": Qt.binding(function() { return iconSource; }),
                    "fallbackIcon": Qt.binding(function() { return fallbackIcon; })
                }
            )
        }
    }

    Label {
        textSize: Label.Small
        anchors {
            left: iconContainer.visible ? iconContainer.right : tabCloseButton.right
            leftMargin: iconContainer.visible ? units.gu(0.5) : 0
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: units.gu(0.5)
        }
        elide: Text.ElideRight
        text: tab.title
        color: tab.foregroundColor
    }
}
