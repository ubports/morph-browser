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
import Ubuntu.Components.Popups 1.3
import ".."

Item {
    id: root

    property alias model: repeater.model

    property real minTabWidth: 0 //units.gu(6)
    property real maxTabWidth: units.gu(20)
    property real tabWidth: model ? Math.max(Math.min(tabsContainer.maxWidth / model.count, maxTabWidth), minTabWidth) : 0

    property bool incognito: false

    signal requestNewTab(int index, bool makeCurrent)

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

        onClicked: root.requestNewTab(root.model.count, true)
    }

    Component {
        id: contextualOptionsComponent
        ActionSelectionPopover {
            id: menu
            objectName: "tabContextualActions"
            property int targetIndex

            actions: ActionList {
                Action {
                    objectName: "tab_action_new_tab"
                    text: i18n.tr("New Tab")
                    onTriggered: root.requestNewTab(menu.targetIndex + 1, false)
                }
                Action {
                    objectName: "tab_action_reload"
                    text: i18n.tr("Reload")
                    enabled: root.model.get(menu.targetIndex).url.toString().length > 0
                    onTriggered: {
                        var tab = root.model.get(menu.targetIndex)
                        if (tab.url.toString().length > 0) tab.webview.reload()
                    }
                }
                Action {
                    objectName: "tab_action_close_tab"
                    text: i18n.tr("Close Tab")
                    onTriggered: internal.closeTab(menu.targetIndex)
                }
            }
        }
    }

    Item {
        id: tabsContainer
        objectName: "tabsContainer"

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: tabWidth * root.model.count
        readonly property real maxWidth: root.width - newTabButton.width - units.gu(2)

        Repeater {
            id: repeater

            property bool reordering: false

            delegate: Item {
                id: tabDelegate
                objectName: "tabDelegate"
                readonly property int tabIndex: index

                anchors {
                    top: tabsContainer.top
                    bottom: tabsContainer.bottom
                }
                width: tabWidth

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    onPressed: {
                        if (mouse.button === Qt.LeftButton) {
                            root.model.currentIndex = index
                        }
                    }
                    onReleased: {
                        if (mouse.button === Qt.MiddleButton) {
                            internal.closeTab(index)
                        }
                    }
                    onClicked: {
                        if (mouse.button === Qt.RightButton) {
                            var menu = PopupUtils.open(contextualOptionsComponent, tabDelegate)
                            menu.targetIndex = index
                        }
                    }

                    // XXX: should not start a drag when middle button was pressed
                    drag {
                        target: tabDelegate
                        axis: Drag.XAxis
                        minimumX: 0
                        maximumX: root.width - tabDelegate.width
                    }
                }

                Binding {
                    target: repeater
                    property: "reordering"
                    value: mouseArea.drag.active
                }

                readonly property string assetPrefix: (index == root.model.currentIndex) ? "assets/tab-active" : (mouseArea.containsMouse ? "assets/tab-hovered" : "assets/tab-inactive")

                Item {
                    anchors.fill: parent

                    Image {
                        id: tabBackgroundLeft
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                        }
                        source: "%1-left.png".arg(assetPrefix)
                    }

                    Image {
                        id: tabBackgroundRight
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            right: parent.right
                            rightMargin: units.gu(-1.5)
                        }
                        source: "%1-right.png".arg(assetPrefix)
                    }

                    Image {
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: tabBackgroundLeft.right
                            right: tabBackgroundRight.left
                        }
                        source: "%1-center.png".arg(assetPrefix)
                        fillMode: Image.TileHorizontally
                    }
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(1.5)
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: units.gu(1)

                    Favicon {
                        id: favicon
                        source: model.icon
                        shouldCache: !incognito
                    }

                    Label {
                        fontSize: "small"
                        color: UbuntuColors.darkGrey
                        text: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                        elide: Text.ElideRight
                        width: parent.width - favicon.width - closeIcon.width - parent.spacing * 2
                    }

                    Icon {
                        id: closeIcon
                        objectName: "closeButton"
                        name: "close"
                        color: UbuntuColors.darkGrey
                        width: units.gu(1.5)
                        height: units.gu(1.5)
                        anchors.verticalCenter: parent.verticalCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: internal.closeTab(index)
                        }
                    }
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

        Rectangle {
            anchors {
                left: parent.left
                bottom: parent.bottom
            }
            width: root.width
            height: units.dp(1)
            color: "#cacaca"
            z: 2
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
