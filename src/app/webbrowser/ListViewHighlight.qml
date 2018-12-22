/*
 * Copyright 2016 Canonical Ltd.
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
import ".."

Rectangle {
    color: "transparent"
    border {
        width: units.dp(1)
        color: ((ListView.view && !ListView.view.currentItem.enabled) ||
                (GridView.view && !GridView.view.currentItem.enabled))
                   ? theme.palette.disabled.focus
                   : theme.palette.normal.focus
    }
    visible: hasKeyboard &&
             ((ListView.view && ListView.view.activeFocus) ||
              (GridView.view && GridView.view.activeFocus))

    readonly property bool hasKeyboard: keyboardModel.count > 0

    FilteredKeyboardModel {
        id: keyboardModel
    }
}
