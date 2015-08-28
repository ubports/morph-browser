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
import webbrowserapp.private 0.1
import ".."

AbstractButton {
    id: item

    property alias icon: favicon.source
    property alias title: titleLabel.text
    property url url
    property bool highlighted: false

    signal removed()

    UbuntuShape {
        visible: item.highlighted
        anchors.fill: parent
        anchors.margins: units.gu(0.5)
        aspect: UbuntuShape.Flat
        backgroundColor: Qt.rgba(0, 0, 0, 0.05)
    }

    Column {
        anchors.centerIn: parent
        spacing: units.gu(1)

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: titleLabel.height

            Favicon {
                id: favicon
                source: item.icon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: titleLabel
                anchors.left: favicon.right
                anchors.leftMargin: units.gu(1)
                anchors.right: parent.right
                anchors.top: parent.top
                text: item.title
                elide: Text.ElideRight
                fontSize: "x-small"
            }
        }

        UbuntuShape {
            id: previewShape
            height: units.gu(10)
            width: units.gu(17)
            anchors.left: parent.left
            source: Image {
                property url previewUrl: Qt.resolvedUrl(cacheLocation + "/captures/" + Qt.md5(item.url) + ".jpg")
                source: FileOperations.exists(previewUrl) ? previewUrl : ""
                sourceSize.height: previewShape.height
                cache: false
            }
            sourceFillMode: UbuntuShape.PreserveAspectCrop
        }
    }
}
