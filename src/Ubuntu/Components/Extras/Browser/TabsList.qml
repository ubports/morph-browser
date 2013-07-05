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
    property alias model: listview.model

    signal newTabClicked()
    signal switchToTabClicked(int index)
    signal tabRemoved(int index)

    color: "#AEA79F"

    Label {
        id: heading
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: units.gu(1)
        }
        height: units.gu(2)
        font.bold: true
        // TRANSLATORS: %1 refers to the number of open tabs
        text: i18n.tr("Open pages %1").arg(model.count)
    }

    ListView {
        id: listview
        anchors {
            top: heading.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        spacing: units.gu(2)
        orientation: ListView.Horizontal
        currentIndex: model.currentIndex

        header: Item {
            width: units.gu(14)
            height: parent.height

            PageDelegate {
                objectName: "newTabDelegate"
                width: units.gu(12)
                height: units.gu(12)
                color: "white"
                Label {
                    anchors.centerIn: parent
                    fontSize: "x-large"
                    text: i18n.tr("+")
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: newTabClicked()
                }
            }
        }

        delegate: ListItem.Empty {
            width: units.gu(12)
            height: units.gu(12)
            showDivider: false

            // FIXME: http://pad.lv/1187476 makes it impossible to swipe a
            // delegate up/down to remove it from an horizontal listview.
            removable: true
            onItemRemoved: tabRemoved(index)

            PageDelegate {
                objectName: "openTabDelegate"
                anchors.fill: parent
                color: (index == currentIndex) ? "#2C001E" : "white"
                title: model.title
            }

            onClicked: switchToTabClicked(index)
        }
    }

    function centerViewOnCurrentTab() {
        listview.positionViewAtIndex(model.currentIndex, ListView.Center)
    }
}
