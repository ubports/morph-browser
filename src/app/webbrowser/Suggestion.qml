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
import Ubuntu.Components.ListItems 1.3 as ListItem

// Not using ListItem.Subtitled because it’s not themable,
// and we want the subText to be on one line only.
ListItem.Base {
    property alias title: label.text
    property alias subtitle: subLabel.text
    property alias icon: icon.name
    property url url

    signal activated(url url)

    __height: Math.max(middleVisuals.height, units.gu(6))
    // disable focus handling
    activeFocusOnPress: false

    Item  {
        id: middleVisuals
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: subLabel.visible ? label.height + subLabel.height : icon.height

        Icon {
            id: icon
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
            }
            width: units.gu(2)
            height: units.gu(2)
            color: theme.palette.selected.base
            asynchronous: true
        }

        Label {
            id: label
            anchors {
                top: subLabel.visible ? parent.top : undefined
                verticalCenter: subLabel.visible ? undefined : parent.verticalCenter
                left: icon.right
                leftMargin: units.gu(2)
                right: parent.right
            }
            color: selected ? "#DB4923" : theme.palette.selected.base
            elide: Text.ElideRight
        }

        Label {
            id: subLabel
            anchors {
                top: label.bottom
                left: icon.right
                leftMargin: units.gu(2)
                right: parent.right
            }
            fontSize: "small"
            elide: Text.ElideRight
            visible: text !== ""
            color: selected ? "#DB4923" : theme.palette.selected.base
        }
    }

    onClicked: activated(url)
}
