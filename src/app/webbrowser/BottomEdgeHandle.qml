/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.0

Item {
    id: bottomEdgeHandle

    readonly property bool dragging: handleArea.drag.active
    readonly property real dragFraction: 1.0 - y / (parent.height - height)

    readonly property var thresholds: [0.0, 0.18, 0.36, 0.54, 1.0]
    readonly property int stage: thresholds.map(function(t) { return dragFraction <= t }).indexOf(true)

    y: parent.height - height
    visible: (stage == 0) || dragging

    function reset() {
        y = parent.height - height
    }

    MouseArea {
        id: handleArea
        anchors.fill: parent
        drag {
            axis: Drag.YAxis
            target: bottomEdgeHandle
            minimumY: 0
            maximumY: bottomEdgeHandle.parent.height - height
        }
        //enabled: bottomEdgeHandle.stage < 4
    }

    Rectangle {
        // temporary, to visualize the handle
        anchors.fill: parent
        color: "lightgrey"
        opacity: 0.8
        visible: parent.enabled
    }
}
