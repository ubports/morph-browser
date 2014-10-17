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
import QtQuick.Layouts 1.0
import Ubuntu.Components 1.1
import ".."
import "upstreamcomponents"

ListItemWithActions {
    id: urlDelegate

    property alias icon: icon.source
    property alias title: title.text
    property alias url: url.text
    color: "#f6f6f6"

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: units.gu(1)

        UbuntuShape {
            id: iconContainer
            Layout.maximumWidth: units.gu(3)
            Layout.maximumHeight: units.gu(3)

            Favicon {
                id: icon
                anchors.centerIn: parent
            }
        }

        Column {
            Layout.fillWidth: true

            Label {
                id: title

                fontSize: "x-small"
                color: "#5d5d5d"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Label {
                id: url

                fontSize: "xx-small"
                color: "#5d5d5d"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
