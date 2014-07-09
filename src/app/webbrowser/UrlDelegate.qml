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
import Ubuntu.Components 0.1

Item {
    id: urlDelegate

    property alias icon: icon.source
    property alias url: url.text
    property alias title: title.text

    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: urlDelegate.clicked()
    }

    Row {
        anchors.fill: parent
        spacing: units.gu(1)

        UbuntuShape {
            id: iconShape
            height: parent.height
            width: parent.height

            Image {
                id: icon
                anchors.centerIn: parent
                width: units.dp(16)
                height: units.dp(16)
            }
        }

        Column {
            width: parent.width - iconShape.width - spacing
            Label {
                id: title
                width: parent.width
                font.bold: true

                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Label {
                id: url
                width: parent.width
                fontSize: "small"

                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
