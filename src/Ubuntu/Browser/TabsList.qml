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

Rectangle {
    color: "#AEA79F"
    opacity: 0.9

    property alias model: listview.model

    signal newTabClicked()
    signal switchToTabClicked(int index)

    Item {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        PageDelegate {
            id: newTabDelegate
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: units.gu(20)
            color: "white"
            Label {
                anchors.centerIn: parent
                fontSize: "x-large"
                text: i18n.tr("+")
            }
            onClicked: newTabClicked()
        }

        ListView {
            id: listview

            anchors {
                left: newTabDelegate.right
                leftMargin: units.gu(1)
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }

            orientation: ListView.Horizontal
            spacing: units.gu(1)
            clip: true

            currentIndex: model.currentIndex

            delegate: PageDelegate {
                width: units.gu(20)
                color: ListView.isCurrentItem ? "#2C001E" : "white"
                height: parent.height
                title: model.title
                onClicked: switchToTabClicked(index)
            }
        }
    }
}
