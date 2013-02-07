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

Rectangle {
    property string url

    signal refreshClicked()

    color: "white"

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(2)

        spacing: units.gu(3)

        Label {
            width: parent.width
            fontSize: "large"
            text: "Network Error"
        }

        Label {
            width: parent.width
            text: "It appears you are having trouble viewing %1.".arg(url)
            wrapMode: Text.Wrap
        }

        Label {
            width: parent.width
            text: "Ubuntu suggests you check your network settings and try refreshing the page."
            wrapMode: Text.Wrap
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Refresh page"
            width: units.gu(16) // XXX: is there a way to make the button accommodate the width of its text?
            onClicked: refreshClicked()
        }
    }
}
