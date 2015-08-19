/*
 * Copyright 2015 Canonical Ltd.
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

import QtQuick 2.4

Item {
    function processKey(key, modifiers) {
        for (var i = 0; i < data.length; i++) {
            var shortcut = data[i];

            if (!shortcut.enabled) continue
            if (key !== shortcut.key) continue

            if (shortcut.modifiers === Qt.NoModifier) {
                if (modifiers === Qt.NoModifier) {
                    shortcut.trigger()
                    return true
                }
            } else if ((modifiers & shortcut.modifiers) === shortcut.modifiers) {
                shortcut.trigger()
                return true
            }
        }
        return false
    }
}
