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

Column {
    id: bookmarksList

    property alias model: bookmarksListRepeater.model
    property alias footerLabelText: footerLabel.text

    signal bookmarkClicked(url url)
    signal footerLabelClicked()

    anchors {
        left: parent.left
        right: parent.right
        margins: units.gu(2)
    }

    width: parent.width

    spacing: units.gu(1)

    Repeater {
        id: bookmarksListRepeater

        delegate: UrlDelegate{
            width: parent.width
            height: units.gu(5)

            favIcon: model.icon
            label: model.title ? model.title : model.url
            url: model.url

            onClicked: bookmarkClicked(model.url)
        }
    }

    Rectangle {
        width: parent.width
        height: footerLabel.height + units.gu(6)

        MouseArea {
            anchors.centerIn: footerLabel

            width: footerLabel.width + units.gu(4)
            height: footerLabel.height + units.gu(4)

            onClicked: footerLabelClicked()
        }

        Label {
            id: footerLabel
            anchors.centerIn: parent

            font.bold: true
        }
    }
}
