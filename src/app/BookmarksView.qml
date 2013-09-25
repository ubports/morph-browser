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

Item {
    property QtObject bookmarksModel

    signal bookmarkClicked(url url)

    Rectangle {
        anchors.fill: parent
        color: "#EEEEEE"
    }

    GridView {
        anchors {
            fill: parent
            margins: units.gu(2)
        }
        clip: true

        model: bookmarksModel

        cellWidth: units.gu(14)
        cellHeight: units.gu(14)

        delegate: PageDelegate {
            width: units.gu(12)
            height: units.gu(12)

            label: model.title ? model.title : model.url

            property url thumbnailSource: "image://webthumbnail/" + model.url
            thumbnail: WebThumbnailer.thumbnailExists(model.url) ? thumbnailSource : ""

            onClicked: bookmarkClicked(model.url)
        }
    }
}
