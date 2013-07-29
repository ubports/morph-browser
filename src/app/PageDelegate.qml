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
    property alias thumbnail: thumbnail.source
    property alias label: label.text

    UbuntuShape {
        id: shape
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: width

        image: Image {
            id: thumbnail
        }
    }

    Label {
        id: label
        anchors {
            top: shape.bottom
            topMargin: units.gu(1)
            left: parent.left
            right: parent.right
        }
        height: units.gu(1)
        fontSize: "small"
        elide: Text.ElideRight
    }
}
