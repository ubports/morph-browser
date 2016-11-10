/*
 * Copyright 2015-2016 Canonical Ltd.
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

import webbrowserapp.private 0.1

import "."
import ".."

Item {
    id: root

    property alias model: repeater.model

    property BrowserWindow thisWindow

    property real minTabWidth: 0 //units.gu(6)
    property real maxTabWidth: units.gu(20)
    property real tabWidth: model ? Math.max(Math.min(tabsContainer.maxWidth / model.count, maxTabWidth), minTabWidth) : 0

    // Minimum size of the larger tab
    readonly property real minActiveTabWidth: units.gu(10)

    // When there is a larger tab, calc the smaller tab size
    readonly property real nonActiveTabWidth: (tabsContainer.maxWidth - minActiveTabWidth) / Math.max(model.count - 1, 1)

    // The size of the right margin of the tab
    readonly property real rightMargin: units.dp(1)

    // Whether there will be one larger tab or not
    readonly property bool unevenTabWidth: tabWidth + rightMargin < minActiveTabWidth

    property bool incognito: false

    property color fgColor: Theme.palette.normal.baseText

    property bool touchEnabled: true

    signal switchToTab(int index)
    signal requestNewTab(int index, bool makeCurrent)
    signal requestNewWindowFromTab(var tab, var callback)
    signal tabClosed(int index, bool moving)

    MouseArea {
        anchors.fill: parent
        onWheel: {
            var angle = (wheel.angleDelta.x != 0) ? wheel.angleDelta.x : wheel.angleDelta.y
            if ((angle < 0) && (root.model.currentIndex < (root.model.count - 1))) {
                switchToTab(root.model.currentIndex + 1)
            } else if ((angle > 0) && (root.model.currentIndex > 0)) {
                switchToTab(root.model.currentIndex - 1)
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
            color: incognito ? "white" : root.fgColor
        }

        onClicked: root.requestNewTab(root.model.count, true)
    }

    Component {
        id: contextualOptionsComponent
        ActionSelectionPopover {
            id: menu
            objectName: "tabContextualActions"
            property int targetIndex
            readonly property var tab: root.model.get(targetIndex)

            actions: ActionList {
                Action {
                    objectName: "tab_action_new_tab"
                    text: i18n.tr("New Tab")
                    onTriggered: root.requestNewTab(menu.targetIndex + 1, false)
                }
                Action {
                    objectName: "tab_action_reload"
                    text: i18n.tr("Reload")
                    enabled: menu.tab.url.toString().length > 0
                    onTriggered: menu.tab.reload()
                }
                Action {
                    objectName: "tab_action_move_to_new_window"
                    text: i18n.tr("Move to New Window")
                    onTriggered: {
                        // callback function only removes from model
                        // and not destroy as webview is in new window
                        root.requestNewWindowFromTab(menu.tab, function() { root.tabClosed(menu.targetIndex, true); });
                    }
                }
                Action {
                    objectName: "tab_action_close_tab"
                    text: i18n.tr("Close Tab")
                    onTriggered: root.tabClosed(menu.targetIndex, false)
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

        readonly property int maxYDiff: height / 4

        function sign(number) { return number / Math.abs(number); }

        Repeater {
            id: repeater

            property bool reordering: false

            delegate: MouseArea {
                id: tabDelegate
                objectName: "tabDelegate"

                readonly property int tabIndex: index
                readonly property BrowserTab tab: root.model.get(index)
                readonly property BrowserWindow tabWindow: root.thisWindow

                property real rightMargin: units.dp(1)
                width: getSize(index)
                height: tabsContainer.height
                y: tabsContainer.y  // don't use anchor otherwise drag doesn't work

                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                readonly property bool dragging: drag.active
                drag {
                    target: (pressedButtons === Qt.LeftButton) ? tabDelegate : null
                    // FIXME: disable drag and drop on mir pad.lv/1627013
                    axis: __platformName != "ubuntumirclient" ? Drag.XAndYAxis : Drag.XAxis
                    minimumX: 0
                    maximumX: root.width - tabDelegate.width
                    filterChildren: true
                }

                DragHelper {
                    id: dragHelper
                    expectedAction: Qt.IgnoreAction | Qt.CopyAction | Qt.MoveAction
                    mimeType: "webbrowser/tab-" + (root.incognito ? "incognito" : "public")
                    previewBorderWidth: units.gu(1)
                    previewSize: Qt.size(units.gu(35), units.gu(22.5))
                    previewTopCrop: chrome.height
                    source: tabDelegate
                }

                TabItem {
                    active: tabIndex === root.model.currentIndex
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: tabsContainer.height
                    hoverable: true
                    incognito: root.incognito
                    title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                    icon: model.icon
                    fgColor: root.fgColor

                    touchEnabled: root.touchEnabled

                    rightMargin: root.rightMargin

                    // Keep the visual tabitem within maxYDiff of starting point when
                    // dragging vertically so that it doesn't cover other elements
                    y: Math.abs(parent.y) > tabsContainer.maxYDiff ? (tabsContainer.sign(parent.y) * tabsContainer.maxYDiff) - parent.y : 0

                    onClosed: root.tabClosed(index, false)
                    onSelected: root.switchToTab(index)
                    onContextMenu: PopupUtils.open(contextualOptionsComponent, tabDelegate, {"targetIndex": index})
                }

                Binding {
                    target: repeater
                    property: "reordering"
                    value: dragging
                }

                Behavior on width { NumberAnimation { duration: 250 } }

                Binding on x {
                    when: !dragging
                    value: getLeftX(index)
                }

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                    }
                }

                NumberAnimation {
                    id: resetVerticalAnimation
                    target: tabDelegate
                    duration: 250
                    property: "y"
                    to: 0
                }

                onPositionChanged: {
                    // FIXME: disable drag and drop on mir pad.lv/1627013
                    if (Math.abs(y) > height && __platformName != "ubuntumirclient") {
                        // Reset visual position of tab delegate
                        resetVerticalAnimation.start();

                        if (mouse.buttons === Qt.LeftButton) {
                            // Generate tab preview for drag handle
                            dragHelper.previewUrl = PreviewManager.previewPathFromUrl(tab.url); 

                            var dropAction = dragHelper.execDrag(tab.url);

                            // IgnoreAction - no DropArea accepted so New Window
                            // MoveAction   - DropArea accept but different window
                            // CopyAction   - DropArea accept but same window

                            if (dropAction === Qt.MoveAction) {
                                // Moved into another window

                                // drag.active does not become false when
                                // closing the tab so set reordering back
                                repeater.reordering = false;

                                // Just remove from model and do not destory
                                // as webview is used in other window
                                root.tabClosed(index, true);
                            } else if (dropAction === Qt.CopyAction) {
                                // Moved into the same window

                                // So no action
                            } else if (dropAction === Qt.IgnoreAction) {
                                // Moved outside of any window

                                // drag.active does not become false when
                                // closing the tab so set reordering back
                                repeater.reordering = false;

                                // callback function only removes from model
                                // and not destroy as webview is in new window
                                root.requestNewWindowFromTab(tab, function() { root.tabClosed(index, true); })
                            } else {
                                // Unknown state
                                console.debug("Unknown drop action:", dropAction);
                            }
                        }
                    }
                }
                onReleased: resetVerticalAnimation.start();

                function getLeftX(index) {
                    if (unevenTabWidth) {
                        if (index > root.model.currentIndex) {
                            return minActiveTabWidth + (nonActiveTabWidth * (index - 1))
                        } else {
                            return nonActiveTabWidth * index
                        }
                    } else {
                        // Do not depend on width otherwise X updates after
                        // Width causing the animation to be two stage
                        // instead perform same calculation (tabWidth + rightMargin)
                        return index * (tabWidth + rightMargin)
                    }
                }

                function getSize(index) {
                    if (unevenTabWidth) {
                        // Uneven tabs so use large or small depending which index
                        if (index === root.model.currentIndex) {
                            return minActiveTabWidth
                        } else {
                            return nonActiveTabWidth
                        }
                    } else {
                        return tabWidth + rightMargin
                    }
                }

                onXChanged: {
                    if (!dragging) return

                    var leftX = getLeftX(index)

                    if (x < (leftX - getSize(index - 1) / 2) && index > 0) {
                        root.model.move(index, index - 1)
                    } else if ((x > (leftX + getSize(index + 1) / 2)) && (index < (root.model.count - 1))) {
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
}
