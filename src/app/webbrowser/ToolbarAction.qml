/*
 * Copyright 2014-2015 Canonical Ltd.
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

AbstractButton {
    property alias iconName: icon.name
    property alias text: label.text

    opacity: enabled ? 1.0 : 0.3
    width: Math.max(label.paintedWidth, icon.width)

    Item {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: width

        Icon {
            id: icon

            width: units.gu(2)
            height: width
            anchors {
                top: parent.top
                topMargin: units.gu(1)
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Label {
        id: label
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        horizontalAlignment: Text.AlignHCenter
        fontSize: "x-small"
        maximumLineCount: 1
        elide: Text.ElideMiddle
    }
}
