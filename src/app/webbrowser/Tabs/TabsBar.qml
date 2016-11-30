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
import QtQml.Models 2.2
import QtQuick.Window 2.2
import Ubuntu.Components 1.3
import "." as LocalTabs

import Tabs.DragHelper 0.1

Rectangle {
    id: tabsBar

    implicitWidth: units.gu(60)
    implicitHeight: units.gu(3)

    property color backgroundColor: "white"
    property color foregroundColor: "black"
    property color contourColor: Qt.rgba(0.0, 0.0, 0.0, 0.2)
    property color actionColor: "black"
    property color highlightColor: Qt.rgba(actionColor.r, actionColor.g, actionColor.b, 0.1)
    /* 'model' needs to have the following members:
         property int selectedIndex
         function selectTab(int index)
         function removeTab(int index)
         function moveTab(int from, int to)
    */
    property var model
    property list<Action> actions

    /* To enable drag and drop set to enabled
     *
     * Use expose to set any information you need the DropArea to access
     * Then use drag.source.expose.myproperty
     * 
     * Set mimeType to one of the keys in the DropArea's you want to accept
     * 
     * Set a function for previewUrlFromIndex which is given the index
     * and returns a url to an image, which will be shown in the handle
     */
    readonly property DragAndDropSettings dragAndDrop: DragAndDropSettings {

    }

    signal requestNewWindowFromTab(var tab, var callback)

    /* When a tab is being removed due to it being moved to another window
     * This allows for different code to be run when moving, such as not
     * destroying the tab components
     */
    function removeTabButMoving(index) {
        return removeTab(index);
    }

    function titleFromModelItem(modelItem) {
        return modelItem.title;
    }

    TabStepper {
        id: leftStepper
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        layoutDirection: Qt.LeftToRight
        foregroundColor: tabsBar.foregroundColor
        contourColor: tabsBar.contourColor
        highlightColor: tabsBar.highlightColor
        counter: tabs.indexFirstVisibleItem
        active: tabs.overflow
        onClicked: {
            var nextInvisibleItem = tabs.indexFirstVisibleItem - 1;
            tabs.animatedPositionAtIndex(nextInvisibleItem);
        }
    }

    TabStepper {
        id: rightStepper
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: actions.left
        }
        layoutDirection: Qt.RightToLeft
        foregroundColor: tabsBar.foregroundColor
        contourColor: tabsBar.contourColor
        highlightColor: tabsBar.highlightColor
        counter: tabs.count - tabs.indexLastVisibleItem - 1
        active: tabs.overflow
        onClicked: {
            var nextInvisibleItem = tabs.indexLastVisibleItem + 1;
            tabs.animatedPositionAtIndex(nextInvisibleItem);
        }
    }

    ListView {
        id: tabs
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: tabs.overflow ? leftStepper.right : parent.left
            leftMargin: tabs.overflow ? 0 : units.gu(1)
            right: tabs.overflow ? rightStepper.left : actions.left
        }
        interactive: false
        orientation: ListView.Horizontal
        clip: true
        highlightMoveDuration: UbuntuAnimation.FastDuration

        UbuntuNumberAnimation { id: scrollAnimation; target: tabs; property: "contentX" }

        function animatedPositionAtIndex(index) {
            scrollAnimation.running = false;
            var pos = tabs.contentX;
            var destPos;
            tabs.positionViewAtIndex(index, ListView.Contain);
//             destPos = tabs.contentX;
//             scrollAnimation.from = pos;
//             scrollAnimation.to = destPos;
//             scrollAnimation.running = true;
        }

        property int indexFirstVisibleItem: indexAt(contentX+1, height / 2)
        property int indexLastVisibleItem: indexAt(contentX+width-1, height / 2)
        property real minimumTabWidth: units.gu(15)
        property int maximumTabsCount: Math.floor((tabsBar.width - actions.width - units.gu(1)) / minimumTabWidth)
        property real availableWidth: tabsBar.width - actions.width - units.gu(1)
        property real maximumTabWidth: availableWidth / tabs.count
        readonly property int maxYDiff: 2 //height / 8
        property bool overflow: tabs.count > maximumTabsCount

        displaced: Transition {
            UbuntuNumberAnimation { property: "x" }
        }
        currentIndex: tabsBar.model.selectedIndex
        model: tabsBar.model
        delegate: MouseArea {
            id: tabMouseArea

            width: tab.width
            height: tab.height
            drag {
                target: (tabs.count > 1 || dragAndDrop.enabled) && tab.isFocused ? tab : null
                axis: dragAndDrop.enabled ? Drag.XAndYAxis : Drag.XAxis
                minimumX: tab.isDragged ? -tab.width/2 : -Infinity
                maximumX: tab.isDragged ? tabs.width - tab.width/2 : Infinity
            }
            z: tab.isFocused ? 1 : 0
            Binding {
                target: tabsBar
                property: "selectedTabX"
                value: tabs.x + tab.x + (tab.isDragged ? 0 : tabMouseArea.x - tabs.contentX)
                when: tab.isFocused
            }
            Binding {
                target: tabsBar
                property: "selectedTabWidth"
                value: tab.width
                when: tab.isFocused
            }
            NumberAnimation {
                id: resetVerticalAnimation
                target: tab
                duration: 250
                property: "y"
                to: 0
            }

            onPressed: tabsBar.model.selectTab(index)
            onReleased: resetVerticalAnimation.start()
            onWheel: {
                if (wheel.angleDelta.y >= 0) {
                    tabsBar.model.selectTab(tabsBar.model.selectedIndex - 1);
                } else {
                    tabsBar.model.selectTab(tabsBar.model.selectedIndex + 1);
                }
            }

            hoverEnabled: true

            LocalTabs.Tab {
                id: tab

                anchors.left: tabMouseArea.left
                implicitWidth: tabs.availableWidth / 2
                width: tabs.overflow ? tabs.availableWidth / tabs.maximumTabsCount : Math.min(tabs.maximumTabWidth, implicitWidth)
                height: tabs.height

                // Reference the tab and window so that the dropArea can determine what to do
                readonly property var thisTab: typeof(modelData) === "undefined" ? model : modelData
                readonly property var thisWindow: dragAndDrop.thisWindow

                property bool isDragged: tabMouseArea.drag.active
                property bool isDynamicDragging: false  // used to track when tab is moved by dropArea
                Drag.active: tab.isDragged
                Drag.source: tabMouseArea
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                states: State {
                    name: "dragging"
                    when: tab.isDragged
                    ParentChange { target: tab; parent: tabs }
                    AnchorChanges { target: tab; anchors.left: undefined }
                }
                transitions: Transition {
                    from: "dragging"
                    ParentAnimation {
                        NumberAnimation {
                            property: "x"
                            duration: UbuntuAnimation.FastDuration
                            easing: UbuntuAnimation.StandardEasing
                        }
                    }

                    AnchorAnimation {
                        duration: UbuntuAnimation.FastDuration
                        easing: UbuntuAnimation.StandardEasing
                    }
                }

                isHovered: tabMouseArea.containsMouse
                isFocused: tabsBar.model.selectedIndex == index
                isBeforeFocusedTab: index == tabsBar.model.selectedIndex - 1
                title: tabsBar.titleFromModelItem(typeof(modelData) === "undefined" ? model : modelData)
                backgroundColor: tabsBar.backgroundColor
                foregroundColor: tabsBar.foregroundColor
                contourColor: tabsBar.contourColor
                actionColor: tabsBar.actionColor
                highlightColor: tabsBar.highlightColor
                onClose: tabsBar.model.removeTab(index)
            }

            DropArea {
                id: myDropArea
                anchors.fill: parent
                onEntered: {
                    tabsBar.model.moveTab(drag.source.DelegateModel.itemsIndex,
                                          tabMouseArea.DelegateModel.itemsIndex)
                    if (tabMouseArea.DelegateModel.itemsIndex == tabs.indexLastVisibleItem) {
                        tabs.animatedPositionAtIndex(tabs.indexLastVisibleItem + 1);
                    } else if (tabMouseArea.DelegateModel.itemsIndex == tabs.indexFirstVisibleItem) {
                        tabs.animatedPositionAtIndex(tabs.indexFirstVisibleItem - 1);
                    }
                }
            }

            onPositionChanged: {
                if (!dragAndDrop.enabled || !tabMouseArea.drag.active) {
                    return;
                }

                // Keep the visual tab within maxYDiff of starting point when
                // dragging vertically so that it doesn't cover other elements
                // or appear to be detached
                tab.y = Math.abs(tab.y) > tabs.maxYDiff ? (tab.y > 0 ? 1 : -1) * tabs.maxYDiff : tab.y

                // Initiate drag and drop if mouse y has gone further than the height from the object
                if (mouse.y > height * 2 || mouse.y < -height) {
                    // Reset visual position of tab delegate
                    resetVerticalAnimation.start();

                    // Generate tab preview for drag handle
                    DragHelper.expectedAction = dragAndDrop.expectedAction
                    DragHelper.mimeType = dragAndDrop.mimeType
                    DragHelper.previewBorderWidth = dragAndDrop.previewBorderWidth
                    DragHelper.previewSize = dragAndDrop.previewSize
                    DragHelper.previewTopCrop = dragAndDrop.previewTopCrop
                    DragHelper.previewUrl = dragAndDrop.previewUrlFromIndex(index)
                    DragHelper.source = tab

                    var dropAction = DragHelper.execDrag(index);

                    // IgnoreAction - no DropArea accepted so New Window
                    // MoveAction   - DropArea accept but different window
                    // CopyAction   - DropArea accept but same window

                    if (dropAction === Qt.MoveAction) {
                        // Moved into another window

                        // Just remove from model and do not destroy
                        // as webview is used in other window
                        tabsBar.removeTabButMoving(index);
                    } else if (dropAction === Qt.CopyAction) {
                        // Moved into the same window

                        // So no action
                    } else if (dropAction === Qt.IgnoreAction) {
                        // Moved outside of any window

                        // callback function only removes from model
                        // and not destroy as webview is in new window
                        tabsBar.requestNewWindowFromTab(tabsBar.model.get(index), function() { tabsBar.removeTabButMoving(index); })
                    } else {
                        // Unknown state
                        console.debug("Unknown drop action:", dropAction);
                    }
                }
            }
        }
    }

    property real selectedTabX
    property real selectedTabWidth

    Rectangle {
        id: bottomContourLeft
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        width: MathUtils.clamp(selectedTabX,
                               leftStepper.width, parent.width - (actions.width + rightStepper.width))
        height: units.dp(1)
        color: tabsBar.contourColor
    }

    Rectangle {
        id: bottomContourRight
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        width: MathUtils.clamp(parent.width - selectedTabX - selectedTabWidth,
                               actions.width + rightStepper.width, parent.width - leftStepper.width)
        height: units.dp(1)
        color: tabsBar.contourColor
    }

    Row {
        id: actions

        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        property real actionsSpacing: units.gu(1)
        property real sideMargins: units.gu(1)

        Repeater {
            id: actionsRepeater
            model: tabsBar.actions

            LocalTabs.TabButton {
                iconColor: tabsBar.actionColor
                iconSource: modelData.iconSource
                onClicked: modelData.trigger()
                leftMargin: index == 0 ? actions.sideMargins : actions.actionsSpacing / 2.0
                rightMargin: index == actionsRepeater.count - 1 ? actions.sideMargins : actions.actionsSpacing / 2.0
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        opacity: 0.4
        visible: !Window.active || (dragAndDrop.enabled && dragAndDrop.dropArea ? (DragHelper.dragging && !dragAndDrop.dropArea.inThreshold) : false)
        z: dragAndDrop.enabled && DragHelper.dragging ? 2 : 0
    }
}
