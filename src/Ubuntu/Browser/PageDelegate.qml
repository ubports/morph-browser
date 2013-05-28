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

Rectangle {
    property alias title: title.text
    property alias url: url.text
    signal clicked()

    color: "white"
    radius: units.gu(1)

    Column {
        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(1)
            verticalCenter: parent.verticalCenter
        }
        spacing: units.gu(2)

        Label {
            id: title
            fontSize: "medium"
            width: parent.width
            wrapMode: Text.Wrap
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            height: units.gu(10)
        }

        Label {
            id: url
            fontSize: "small"
            width: parent.width
            wrapMode: Text.Wrap
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
            height: units.gu(5)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }
}
