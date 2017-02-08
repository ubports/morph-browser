/*
 * Copyright 2013-2016 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3

Popover {
    id: itemSelector

    property QtObject selectorModel: model

    property real maximumLabelWidth
    contentWidth: Math.max(model.elementRect.width, maximumLabelWidth + units.gu(6))
    property real listContentHeight: 0 // intermediate property to avoid binding loop
    contentHeight: Math.min(parent.height - units.gu(10), listContentHeight)

    property bool square: true
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        function newColorWithAlpha(color, alpha) {
            return Qt.rgba(color.r, color.g, color.b, alpha);
        }
        border.color: newColorWithAlpha(theme.palette.normal.base, 0.4)
        border.width: units.dp(1)
    }

    property var webview: null
    caller: positioner
    callerMargin: -units.gu(0.5)
    Item {
        id: positioner
        visible: false
        parent: webview
        width: model.elementRect.width
        height: model.elementRect.height
        x: model.elementRect.x
        y: model.elementRect.y
    }

    ListView {
        id: listView
        clip: true
        width: itemSelector.contentWidth
        height: itemSelector.contentHeight
        focus: true
        keyNavigationWraps: true

        property int initialIndex
        Component.onCompleted: currentIndex = initialIndex

        model: selectorModel.items

        delegate: ListItem {
            height: listItemLayout.height + (divider.visible ? divider.height : 0)
            ListItemLayout {
                id: listItemLayout
                padding {
                    top: 0
                    bottom: 0
                }
                height: units.gu(4)
                title.height: units.gu(4)
                title.verticalAlignment: Text.AlignVCenter
                title.text: model.text
                title.onPaintedWidthChanged: maximumLabelWidth = Math.max(title.paintedWidth, maximumLabelWidth)
            }

            color: selected ? Theme.palette.normal.focus : "transparent"
            selected: model.selected
            onActiveFocusChanged: if (activeFocus) selectorModel.items.select(model.index)
            Component.onCompleted: if (model.selected) listView.initialIndex = model.index

            onClicked: {
                selectorModel.items.select(model.index)
                selectorModel.accept()
            }
        }

        section.property: "group"
        section.delegate: ListItems.Header {
            text: section
        }

        onContentHeightChanged: itemSelector.listContentHeight = contentHeight
    }

    Component.onCompleted: show()

    onVisibleChanged: {
        if (!visible) {
            selectorModel.cancel()
        }
    }
}
