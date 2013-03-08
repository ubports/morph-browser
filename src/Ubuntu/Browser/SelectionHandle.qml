/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1

Image {
    property int axis
    property real minimum
    property real maximum
    // Known issue: when dragging outside the window, the drag is canceled,
    // but dragging remains true. See QTBUG-29146.
    property bool dragging: __mousearea.drag.active

    width: units.gu(3)
    height: units.gu(3)

    source: "assets/multi_selection_handle.png"

    MouseArea {
        id: __mousearea

        anchors.fill: parent

        drag {
            target: parent
            axis: parent.axis
            minimumX: parent.minimum
            maximumX: parent.maximum
            minimumY: parent.minimum
            maximumY: parent.maximum
        }
    }
}
