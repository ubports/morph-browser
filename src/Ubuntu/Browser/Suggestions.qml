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
import Ubuntu.Components.ListItems 0.1 as ListItem

Rectangle {
    id: suggestions

    property alias count: listview.count
    property alias contentHeight: listview.contentHeight

    signal selected(url url)

    radius: units.gu(0.5)
    color: "white"
    border {
        color: "#c8c8c8"
        width: 1
    }

    clip: true

    ListView {
        id: listview

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: parent.height

        model: historyMatches

        delegate: ListItem.Subtitled {
            text: title
            subText: url
            onClicked: suggestions.selected(url)
        }
    }

    Scrollbar {
        flickableItem: listview
        align: Qt.AlignTrailing
    }
}
