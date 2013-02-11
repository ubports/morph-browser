/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
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
    property string url
    signal validated()

    TextField {
        id: textField

        anchors.fill: parent

        primaryItem: MouseArea {
            width: __searchIcon.width + units.gu(2)
            height: __searchIcon.height + units.gu(2)
            Image {
                id: __searchIcon
                anchors.centerIn: parent
                source: "assets/icon_search.png"
            }
            onClicked: textField.accepted()
        }

        onAccepted: parent.validate()
    }

    function validate() {
        var address = textField.text.trim()
        if (!address.match(/^http:\/\//) &&
            !address.match(/^https:\/\//) &&
            !address.match(/^file:\/\//) &&
            !address.match(/^[a-z]+:\/\//)) {
            // This is not super smart, but it’s better than nothing…
            address = "http://" + address
        }
        url = address
        validated()
    }

    onUrlChanged: textField.text = url
}
