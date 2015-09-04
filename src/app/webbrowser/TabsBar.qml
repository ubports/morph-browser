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
    id: root

    property alias model: repeater.model

    property real minTabWidth: 0 //units.gu(6)
    property real maxTabWidth: units.gu(20)
    property real tabWidth: model ? Math.max(Math.min(tabsContainer.maxWidth / model.count, maxTabWidth), minTabWidth) : 0

    property bool incognito: false

    signal requestNewTab()

    MouseArea {
        anchors.fill: parent
        onWheel: {
            var angle = (wheel.angleDelta.x != 0) ? wheel.angleDelta.x : wheel.angleDelta.y
            if ((angle < 0) && (root.model.currentIndex < (root.model.count - 1))) {
                root.model.currentIndex++
            } else if ((angle > 0) && (root.model.currentIndex > 0)) {
                root.model.currentIndex--
            }
        }
    }

    MouseArea {
        id: newTabButton
        objectName: "newTabButton"

        anchors {
            left: tabsContainer.right
            leftMargin: units.gu(1)
            top: parent.top
            bottom: parent.bottom
        }
        width: height

        visible: !repeater.reordering

        Icon {
            width: units.gu(2)
            height: units.gu(2)
            anchors.centerIn: parent
            name: "add"
            color: incognito ? "white" : UbuntuColors.darkGrey
        }

        onClicked: root.requestNewTab()
    }

    Item {
        id: tabsContainer
        objectName: "tabsContainer"

        anchors {
            top: parent.top
            bottom: parent.bottom
            bottomMargin: tabsContainer.verticalGap
            left: parent.left
        }
        width: tabWidth * root.model.count
        readonly property real maxWidth: root.width - newTabButton.width - units.gu(2)

        Repeater {
            id: repeater

            property bool reordering: false

            delegate: TabItem {
                id: tabDelegate
                objectName: "tabDelegate"
                readonly property int tabIndex: index

                active: index === root.model.currentIndex
                hoverable: true
                incognito: root.incognito
                title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                icon: model.icon

                anchors.top: tabsContainer.top
                width: tabWidth + rightMargin
                height: tabsContainer.height
                rightMargin: units.dp(1)

                onClosed: internal.closeTab(index)
                onSelected: root.model.currentIndex = index

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    // XXX: should not start a drag when middle button was pressed
                    drag {
                        target: tabDelegate
                        axis: Drag.XAxis
                        minimumX: 0
                        maximumX: root.width - tabDelegate.width
                    }
                    onReleased: root.model.currentIndex = index
                    propagateComposedEvents: true
                }

                Binding {
                    target: repeater
                    property: "reordering"
                    value: mouseArea.drag.active
                }

                Binding on x {
                    when: !mouseArea.drag.active
                    value: index * width
                }

                Behavior on x { NumberAnimation { duration: 250 } }

                onXChanged: {
                    if (!mouseArea.drag.active) return
                    if (x < (index * width - width / 2)) {
                        root.model.move(index, index - 1)
                    } else if ((x > (index * width + width / 2)) && (index < (root.model.count - 1))) {
                        root.model.move(index + 1, index)
                    }
                }

                z: (root.model.currentIndex == index) ? 3 : 1 - index / root.model.count
            }
        }
    }

    QtObject {
        id: internal

        function closeTab(index) {
            var tab = root.model.remove(index)
            if (tab) tab.close()
        }
    }
}
