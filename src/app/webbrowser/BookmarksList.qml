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

Column {
    id: bookmarksList

    property alias model: bookmarksListRepeater.model
    property alias footerLabelText: footerLabel.text
    property alias footerLabelVisible: footerLabel.visible

    signal bookmarkClicked(url url)
    signal footerLabelClicked()

    width: parent.width

    spacing: units.gu(1)

    move: Transition { UbuntuNumberAnimation { properties: "x, y" } }

    Repeater {
        id: bookmarksListRepeater

        delegate: UrlDelegate{
            width: bookmarksList.width
            height: units.gu(5)

            icon: model.icon
            title: model.title ? model.title : model.url
            url: model.url

            onClicked: bookmarkClicked(model.url)
        }
    }

    Rectangle {
        width: parent.width
        height: footerLabel.visible ? footerLabel.height + units.gu(6) : 0

        MouseArea {
            anchors.centerIn: footerLabel

            width: footerLabel.width + units.gu(4)
            height: footerLabel.height + units.gu(4)

            enabled: footerLabel.visible

            onClicked: footerLabelClicked()
        }

        Label {
            id: footerLabel
            anchors.centerIn: parent

            visible: true

            font.bold: true
        }
    }
}
