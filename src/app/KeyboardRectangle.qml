/*
 * Copyright 2013-2015 Canonical Ltd.
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

// This file was originally part of the telephony application.
// It is a workaround required to handle interaction with the OSK,
// until the shell/WM takes care of that on behalf of the applications.

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: keyboardRect
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    // We need to get the values of kayboardRectangle without HIDPI applied
    // To do this we take gridUnit and devide by DEFAULT_GRID_UNIT_PX (8)
    height: Qt.inputMethod.visible ?
            Qt.inputMethod.keyboardRectangle.height / (units.gridUnit / 8) : 0

    Behavior on height {
        UbuntuNumberAnimation {}
    }

    states: [
        State {
            name: "hidden"
            when: keyboardRect.height == 0
        },
        State {
            name: "shown"
            when: keyboardRect.height == Qt.inputMethod.keyboardRectangle.height / (units.gridUnit / 8)
        }
    ]

    function recursiveFindFocusedItem(parent) {
        if (parent.activeFocus) {
            return parent;
        }

        for (var i in parent.children) {
            var child = parent.children[i];
            if (child.activeFocus) {
                return child;
            }

            var item = recursiveFindFocusedItem(child);

            if (item != null) {
                return item;
            }
        }

        return null;
    }

    Connections {
        target: Qt.inputMethod

        onVisibleChanged: {
            if (!Qt.inputMethod.visible) {
                var focusedItem = recursiveFindFocusedItem(keyboardRect.parent);
                if (focusedItem != null) {
                    focusedItem.focus = false;
                }
            }
        }
    }
}
