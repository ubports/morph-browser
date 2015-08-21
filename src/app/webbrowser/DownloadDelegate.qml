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
import Ubuntu.Components 1.2
import ".."

ListItem {
    id: downloadDelegate

    property alias icon: mimeicon.name
    property alias image: thumbimage.source
    property alias extension: extensiontext.text
    property alias title: title.text
    property alias url: url.text
    property alias incomplete: progress.running

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
            sourceFillMode: UbuntuShape.PreserveAspectCrop
            source: Image {
                id: thumbimage
                sourceSize.width: parent.width
                sourceSize.height: parent.height
            }

            Icon {
                id: mimeicon
                anchors.fill: parent
                anchors.margins: units.gu(0.2)
                visible: thumbimage.status !== Image.Ready
            }

            Text {
                id: extensiontext
                font.pointSize: 12
                anchors.centerIn: parent
                visible: text !== "" && thumbimage.status !== Image.Ready
            }

            ActivityIndicator {
                id: progress
                running: false
                visible: running
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
                onTriggered: downloadDelegate.removed()
            }
        ]
    }
}
