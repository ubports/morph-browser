/*
 * Copyright (C) 2016 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Andrew Hayzen <andrew.hayzen@canonical.com>
 */
import QtQuick 2.4

DropArea {
    id: dropArea
    keys: ["x-tabsbar/tab"]

    property real heightThreshold
    readonly property bool inThreshold: containsDrag && drag.y <= heightThreshold
    property var thisWindow
    property var model

//     signal addExistingTab(var tab)

    onDropped: {
        // IgnoreAction - no DropArea accepted so New Window
        // MoveAction   - DropArea accept but different window
        // CopyAction   - DropArea accept but same window
        if (drag.y > heightThreshold) {
            // Dropped in bottom area, creating new window
            drop.accept(Qt.IgnoreAction);
        } else if (drag.source.thisWindow === thisWindow) {
            // Dropped in same window
            drop.accept(Qt.CopyAction);
        } else {
            // Dropped in new window, moving tab
            model.addExistingTab(drag.source.thisTab);
            model.selectTab(model.count - 1);

            drop.accept(Qt.MoveAction);
        }
    }
    onEntered: {
        thisWindow.raise()
        thisWindow.requestActivate();
    }
    onPositionChanged: {
        if (drag.source.thisWindow === thisWindow && drag.y <= heightThreshold) {
            // tab drag is within same window and in chrome
            // so reorder tabs by setting tab x position
            drag.source.x = drag.x - (drag.source.width / 2);
        }
    }
}