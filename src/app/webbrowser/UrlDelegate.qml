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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import ".."

ListItem.Empty {
    id: urlDelegate

    property alias icon: icon.source
    property alias title: title.text
    property alias url: url.text

    showDivider: false
    removable: false

    UbuntuShape {
        id: iconContainer

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: units.gu(3)
        height: units.gu(3)

        Favicon {
            id: icon
            anchors.centerIn: parent
        }
    }

    Label {
        id: title

        anchors {
            left: iconContainer.right
            leftMargin: units.gu(1)
            right: parent.right
            top: iconContainer.top
        }

        fontSize: "x-small"
        color: "#5d5d5d"
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Label {
        id: url

        anchors {
            left: title.left
            right: title.right
            top: title.bottom
            topMargin: units.gu(0.3)
        }

        fontSize: "xx-small"
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
