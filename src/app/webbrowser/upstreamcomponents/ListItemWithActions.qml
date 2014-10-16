/*
 * Copyright (C) 2012-2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.1

Item {
    id: root

    property Action leftSideAction: null
    property list<Action> rightSideActions
    property double defaultHeight: units.gu(8)
    property bool locked: false
    property Action activeAction: null
    property var activeItem: null
    property bool triggerActionOnMouseRelease: false
    property color color: Theme.palette.normal.background
    property color selectedColor: "#E6E6E6"
    property bool selected: false
    property bool selectionMode: false
    property alias internalAnchors: mainContents.anchors
    default property alias contents: mainContents.children

    readonly property double actionWidth: units.gu(5)
    readonly property double leftActionWidth: units.gu(10)
    readonly property double actionThreshold: actionWidth * 0.4
    readonly property double threshold: 0.4
    readonly property string swipeState: main.x == 0 ? "Normal" : main.x > 0 ? "LeftToRight" : "RightToLeft"
    readonly property alias swipping: mainItemMoving.running

    signal itemClicked(var mouse)
    signal itemPressAndHold(var mouse)

    function returnToBoundsRTL()
    {
        var actionFullWidth = actionWidth + units.gu(2)
        var xOffset = Math.abs(main.x)
        var index = Math.min(Math.floor(xOffset / actionFullWidth), rightSideActions.length)

        if (index < 1) {
            main.x = 0
        } else if (index === rightSideActions.length) {
            main.x = -rightActionsView.width
        } else {
            main.x = -(actionFullWidth * index)
        }
    }

    function returnToBoundsLTR()
    {
        var finalX = leftActionWidth
        if (main.x > (finalX * root.threshold))
            main.x = finalX
        else
            main.x = 0
    }

    function returnToBounds()
    {
        if (main.x < 0) {
            returnToBoundsRTL()
        } else if (main.x > 0) {
            returnToBoundsLTR()
        }
    }

    function contains(item, point)
    {
        return (point.x >= item.x) && (point.x <= (item.x + item.width)) && (point.y >= item.y) && (point.y <= (item.y + item.height));
    }

    function getActionAt(point)
    {
        if (contains(leftActionView, point)) {
            return leftSideAction
        } else if (contains(rightActionsView, point)) {
            var newPoint = root.mapToItem(rightActionsView, point.x, point.y)
            for (var i = 0; i < rightActionsRepeater.count; i++) {
                var child = rightActionsRepeater.itemAt(i)
                if (contains(child, newPoint)) {
                    return i
                }
            }
        }
        return -1
    }

    function updateActiveAction()
    {
        if ((main.x <= -root.actionWidth) &&
            (main.x > -rightActionsView.width)) {
            var actionFullWidth = actionWidth + units.gu(2)
            var xOffset = Math.abs(main.x)
            var index = Math.min(Math.floor(xOffset / actionFullWidth), rightSideActions.length)
            index = index - 1
            if (index > -1) {
                root.activeItem = rightActionsRepeater.itemAt(index)
                root.activeAction = root.rightSideActions[index]
            }
        } else {
            root.activeAction = null
        }
    }

    function resetSwipe()
    {
        main.x = 0
    }

    states: [
        State {
            name: "select"
            when: selectionMode || selected
            PropertyChanges {
                target: selectionIcon
                source: Qt.resolvedUrl("ListItemWithActionsCheckBox.qml")
                anchors.leftMargin: units.gu(2)
            }
            PropertyChanges {
                target: root
                locked: true
            }
            PropertyChanges {
                target: main
                x: 0
            }
        }
    ]

    height: defaultHeight
    clip: height !== defaultHeight

    Rectangle {
        id: leftActionView

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: main.left
        }
        width: root.leftActionWidth + actionThreshold
        visible: leftSideAction
        color: "red"

        Icon {
            anchors {
                centerIn: parent
                horizontalCenterOffset: actionThreshold / 2
            }
            name: leftSideAction ? leftSideAction.iconName : ""
            color: Theme.palette.selected.field
            height: units.gu(3)
            width: units.gu(3)
        }
    }

    Item {
       id: rightActionsView

       anchors {
           top: main.top
           left: main.right
           leftMargin: units.gu(1)
           bottom: main.bottom
       }
       visible: rightSideActions.length > 0
       width: rightActionsRepeater.count > 0 ? rightActionsRepeater.count * (root.actionWidth + units.gu(2)) + actionThreshold : 0
       Row {
           anchors.fill: parent
           spacing: units.gu(2)
           Repeater {
               id: rightActionsRepeater

               model: rightSideActions
               Item {
                   property alias image: img

                   anchors {
                       top: parent.top
                       bottom: parent.bottom
                   }
                   width: root.actionWidth

                   Icon {
                       id: img

                       anchors.centerIn: parent
                       width: units.gu(3)
                       height: units.gu(3)
                       name: iconName
                       color: root.activeAction === modelData || !root.triggerActionOnMouseRelease ? UbuntuColors.lightAubergine : Theme.palette.selected.background
                   }
               }
           }
       }
    }


    Rectangle {
        id: main
        objectName: "mainItem"

        anchors {
            top: parent.top
            bottom: parent.bottom
        }

        width: parent.width
        color: root.selected || (mouseArea.pressed && swipeState === "Normal" )? root.selectedColor : root.color

        Loader {
            id: selectionIcon

            anchors {
                left: main.left
                verticalCenter: main.verticalCenter
            }
            width: (status === Loader.Ready) ? item.implicitWidth : 0
            visible: (status === Loader.Ready) && (item.width === item.implicitWidth)
            Behavior on width {
                NumberAnimation {
                    duration: UbuntuAnimation.SnapDuration
                }
            }
        }


        Item {
            id: mainContents

            anchors {
                left: selectionIcon.right
                leftMargin: units.gu(2)
                top: parent.top
                topMargin: units.gu(1)
                right: parent.right
                rightMargin: units.gu(2)
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
        }

        Behavior on x {
            UbuntuNumberAnimation {
                id: mainItemMoving

                easing.type: Easing.OutElastic
                duration: UbuntuAnimation.SlowDuration
            }
        }
        Behavior on color {
            enabled: (root.color != root.selectedColor)
           ColorAnimation {}
        }
    }

    SequentialAnimation {
        id: triggerAction

        property var currentItem: root.activeItem ? root.activeItem.image : null

        running: false
        ParallelAnimation {
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
            UbuntuNumberAnimation {
                target: triggerAction.currentItem
                properties: "width, height"
                from: units.gu(3)
                to: root.actionWidth
                duration: UbuntuAnimation.SlowDuration
                easing {type: Easing.InOutBack; }
            }
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "width, height"
            value: units.gu(3)
        }
        PropertyAction {
            target: triggerAction.currentItem
            properties: "opacity"
            value: 1.0
        }
        ScriptAction {
            script: root.activeAction.triggered(root)
        }
        PauseAnimation {
            duration: 500
        }
        UbuntuNumberAnimation {
            target: main
            property: "x"
            to: 0

        }
    }

    MouseArea {
        id: mouseArea

        property bool locked: root.locked || ((root.leftSideAction === null) && (root.rightSideActions.count === 0))
        property bool manual: false

        anchors.fill: parent
        drag {
            target: locked ? null : main
            axis: Drag.XAxis
            minimumX: rightActionsView.visible ? -(rightActionsView.width + root.actionThreshold) : 0
            maximumX: leftActionView.visible ? leftActionView.width : 0
        }

        onReleased: {
            if (root.triggerActionOnMouseRelease && root.activeAction) {
                triggerAction.start()
            } else {
                root.returnToBounds()
                root.activeAction = null
            }
        }
        onClicked: {
            if (main.x === 0) {
                root.itemClicked(mouse)
            } else if (main.x > 0) {
                var action = getActionAt(Qt.point(mouse.x, mouse.y))
                if (action && action !== -1) {
                    action.triggered(root)
                }
            } else {
                var actionIndex = getActionAt(Qt.point(mouse.x, mouse.y))
                if (actionIndex !== -1) {
                    root.activeItem = rightActionsRepeater.itemAt(actionIndex)
                    root.activeAction = root.rightSideActions[actionIndex]
                    triggerAction.start()
                    return
                }
            }
            root.resetSwipe()
        }

        onPositionChanged: {
            if (mouseArea.pressed) {
                updateActiveAction()
            }
        }
        onPressAndHold: {
            if (main.x === 0) {
                root.itemPressAndHold(mouse)
            }
        }
        z: -1
    }

    InverseMouseArea {
        anchors.fill: parent
        enabled: swipeState !== "Normal"
        topmostItem: true
        propagateComposedEvents: true

        onClicked: {
            root.resetSwipe()
            mouse.accepted = false
        }
    }
}
