/*
 * Copyright 2014-2016 Canonical Ltd.
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

SwipeArea {
    direction: SwipeArea.Upwards

    readonly property real dragFraction: dragging ? Math.min(1.0, Math.max(0.0, distance / parent.height)) : 0.0
    readonly property var thresholds: [0.05, 0.18, 0.36, 0.54, 1.0]
    readonly property int stage: thresholds.map(function(t) { return dragFraction <= t }).indexOf(true)
}
