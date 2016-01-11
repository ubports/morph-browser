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

Rectangle {   
    id: progressBar

    property real progress
    property bool indeterminateProgress: false

    radius: width/3
    color: Theme.palette.normal.base

    Rectangle {
        id: currentProgress
        height: parent.height
        radius: parent.radius
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        color: UbuntuColors.orange
        width: indeterminateProgress ? parent.width / 6 : (progress / 100) * parent.width

        SequentialAnimation {
            running: indeterminateProgress
            onRunningChanged: {
                currentProgress.anchors.leftMargin = 0;
            }
            loops: Animation.Infinite
            PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: 0.0; to: parent.width  - parent.width / 6; duration: UbuntuAnimation.SleepyDuration; easing.type:  Easing.InOutQuad; }
            PropertyAnimation { target: currentProgress.anchors; property: "leftMargin"; from: parent.width  - parent.width / 6; to: 0; duration: UbuntuAnimation.SleepyDuration; easing.type: Easing.InOutQuad; }
        }
    }
}
