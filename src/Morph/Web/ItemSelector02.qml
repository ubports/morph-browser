/*
 * Copyright 2013-2017 Canonical Ltd.
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

Item {
    id: itemSelector

    property QtObject selectorModel: model

    property var webview: null
    property real maximumLabelWidth

    property real contentWidth: Math.max(model.elementRect.width, maximumLabelWidth + units.gu(6))
    property real contentHeight
    width: contentWidth
    height: contentHeight

    property real listContentHeight: (listView.count + listView.sectionCount) * (listItemHeight + units.dp(1))
    property real listItemHeight: units.gu(4)
    property real addressBarHeight: webview.locationBarController.height
    property bool isAbove

    // When the webview's size changes, dismiss the menu.
    // Ideally we would call updatePosition instead but because model.elementRect
    // is not updated, it would result in incorrect positioning.
    Connections {
        target: webview
        onWidthChanged: selectorModel.cancel()
        onHeightChanged: selectorModel.cancel()
    }
    onListContentHeightChanged: updatePosition()
    onAddressBarHeightChanged: updatePosition()

    function updatePosition() {
        itemSelector.x = model.elementRect.x;
        var availableAbove = model.elementRect.y - addressBarHeight;
        var availableBelow = webview.height - model.elementRect.y - model.elementRect.height;

        if (availableBelow >= listContentHeight || availableBelow >= availableAbove) {
            // position popover below the box
            itemSelector.isAbove = false;
            itemSelector.contentHeight = Math.min(availableBelow, listContentHeight);
            itemSelector.y = model.elementRect.y + model.elementRect.height;
        } else {
            // position popover above the box
            itemSelector.isAbove = true;
            itemSelector.contentHeight = Math.min(availableAbove, listContentHeight);
            itemSelector.y = model.elementRect.y - itemSelector.contentHeight;
        }
    }

    Keys.onEscapePressed: selectorModel.cancel()
    Keys.onReturnPressed: selectorModel.accept()
    Keys.onPressed: {
        switch (event.key) {
          // eat up, down, left, right keys
          case Qt.Key_Up:
          case Qt.Key_Down:
          case Qt.Key_Left:
          case Qt.Key_Right:
              event.accepted = true;
              break;
        }
    }

    // eat mouse events beneath the list so that they never reach the webview below
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true
    }

    // eat mouse events around the list so that they never reach the webview below
    InverseMouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: selectorModel.accept()
        onWheel: wheel.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.overlay
        function newColorWithAlpha(color, alpha) {
            return Qt.rgba(color.r, color.g, color.b, alpha);
        }
        border.color: newColorWithAlpha(theme.palette.normal.base, 0.4)
        border.width: units.dp(1)
    }

    ListView {
        id: listView
        clip: true
        width: itemSelector.contentWidth
        height: itemSelector.contentHeight
        focus: true

        // Forces all delegates to be instantiated so that initialIndex is
        // set adequately to the index of the selected item
        cacheBuffer: 32767
        property int initialIndex
        Component.onCompleted: {
            // calling forceLayout ensures that all delegates have been created and
            // that initialIndex is set adequately as a consequence
            forceLayout()
            currentIndex = initialIndex
            positionViewAtIndex(initialIndex, ListView.Contain)
        }

        model: selectorModel.items
        property int sectionCount: 0

        delegate: ListItem {
            height: listItemLayout.height + (divider.visible ? divider.height : 0)
            ListItemLayout {
                id: listItemLayout
                padding {
                    top: 0
                    bottom: 0
                }
                height: listItemHeight
                title.height: listItemHeight
                title.verticalAlignment: Text.AlignVCenter
                title.text: model.text
                title.onContentWidthChanged: maximumLabelWidth = Math.max(title.contentWidth, maximumLabelWidth)
            }

            color: selected ? theme.palette.selected.focus : "transparent"
            selected: focus
            Component.onCompleted: if (model.selected) listView.initialIndex = model.index

            function selectAndClose() {
                selectorModel.items.select(model.index)
                selectorModel.accept()
            }

            Keys.onReturnPressed: selectAndClose()
            // Use a separate MouseArea because ListItem.onClicked is called
            // when the menu has just been created and the enter key is released
            MouseArea {
                anchors.fill: parent
                onClicked: selectAndClose()
            }
        }

        section.property: "group"
        section.delegate: ListItem {
            height: listItemHeight + (divider.visible ? divider.height : 0)
            Component.onCompleted: listView.sectionCount += 1
            ListItemLayout {
                padding {
                    top: 0
                    bottom: 0
                }
                height: listItemHeight
                title.verticalAlignment: Text.AlignVCenter
                title.height: listItemHeight
                title.text: section
                title.font.bold: true
                title.onContentWidthChanged: maximumLabelWidth = Math.max(title.contentWidth, maximumLabelWidth)
            }
        }
    }

    Scrollbar {
        flickableItem: listView
        align: Qt.AlignTrailing
    }
}
