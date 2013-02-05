/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    property bool shown: false
    property bool locked: false
    property Item contents: null
    onContentsChanged: {
        if (contents) {
            contents.parent = bar
        }
    }

    anchors.left: parent.left
    anchors.right: parent.right

    height: bar.height - bar.y

    function show() {
        bar.y = 0
        if (contents) {
            contents.forceActiveFocus()
        }
        shown = true
    }

    function hide() {
        bar.y = bar.height
        shown = false
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: bar.height
        enabled: !parent.locked

        drag.target: bar
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: height + bar.height

        propagateComposedEvents: true

        property int __pressedY
        property int __lastY
        property int __lastDrag

        onPressed: {
            __pressedY = mouse.y
            __lastY = __pressedY
            __lastDrag = 0
        }

        onPositionChanged: {
            var drag = __lastY - mouse.y
            __lastY = mouse.y
            if (drag != 0 || __lastDrag == 0) {
                __lastDrag = drag
            }
        }

        function __doneDragging() {
            if (__lastDrag > 0) {
                show()
            } else if (__lastDrag < 0) {
                hide()
            } else if (shown) {
                show()
            } else {
                hide()
            }
        }

        onReleased: __doneDragging()
        onCanceled: __doneDragging()

        Item {
            id: bar

            height: contents ? contents.height : 0
            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height

            Behavior on y {
                NumberAnimation {
                    duration: 150
                }
            }
        }
    }
}
