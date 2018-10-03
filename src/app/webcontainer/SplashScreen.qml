/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.OnlineAccounts 0.1

Rectangle {
    id: root

    property string applicationName
    property alias iconSource: icon.source
    default property alias contents: contentsHolder.data

    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        contentHeight: Math.max(contentItem.childrenRect.height, height)

        Column {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: units.gu(2)

            Icon {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(10)
                height: width
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                fontSize: "x-large"
                text: root.applicationName
            }

            Item {
                id: contentsHolder
                anchors.left: parent.left
                anchors.right: parent.right
                height: childrenRect.height
            }
        }
    }
}
