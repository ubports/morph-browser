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
    property Item contents: null
    onContentsChanged: {
        if (contents) {
            contents.parent = bar
        }
    }

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: bar.height - bar.y

    function show() {
        bar.y = 0
        bar.shown = true
    }

    function hide() {
        bar.y = bar.height
        bar.shown = false
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: bar.height

        drag.target: bar
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: height + bar.height

        propagateComposedEvents: true

        property int __pressedY
        onPressed: {
            __pressedY = mouse.y;
        }

        onReleased: {
            var shown = !bar.shown
            // check if there was at least some movement to avoid displaying
            // the bar on clicking
            if (Math.abs(__pressedY - mouse.y) < units.gu(1)) {
                shown = bar.shown
            }
            if (shown) {
                show()
            } else {
                hide()
            }
        }

        Item {
            id: bar

            property bool shown: false

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
