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

import QtQuick 2.0
import Ubuntu.Components 1.3
import ".."

ListItem {
    id: urlDelegate

    property alias icon: icon.source
    property alias title: title.text
    property alias url: url.text

    divider.visible: false

    signal removed()

    Row {
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: units.gu(1.5)
        }
        spacing: units.gu(1)

        UbuntuShape {
            id: iconContainer
            width: units.gu(3)
            height: width

            Favicon {
                id: icon
                anchors.centerIn: parent
            }
        }

        Column {
            width: parent.width - iconContainer.width - parent.spacing
            height: parent.height

            Label {
                id: title

                fontSize: "x-small"
                color: UbuntuColors.darkGrey
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Label {
                id: url

                fontSize: "xx-small"
                color: UbuntuColors.darkGrey
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    leadingActions: ListItemActions {
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                onTriggered: urlDelegate.removed()
            }
        ]
    }
}
