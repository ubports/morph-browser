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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem

Popover {
    id: __popover

    property Item selection: null

    grabDismissAreaEvents: false

    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        ListItem.Empty {
            Label {
                anchors.centerIn: parent
                text: "Share"
            }
            onClicked: {
                __popover.selection.share()
                __popover.selection.dismiss()
            }
        }
        ListItem.Empty {
            Label {
                anchors.centerIn: parent
                text: "Save"
            }
            onClicked: {
                __popover.selection.save()
                __popover.selection.dismiss()
            }
        }
        ListItem.Empty {
            Label {
                anchors.centerIn: parent
                text: "Copy"
            }
            onClicked: {
                __popover.selection.copy()
                __popover.selection.dismiss()
            }
        }
    }
}
