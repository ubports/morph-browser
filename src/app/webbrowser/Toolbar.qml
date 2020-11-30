/*
 * Copyright 2014-2015 Canonical Ltd.
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

Rectangle {
    id: toolbar

    color: theme.palette.normal.foreground

    Image {
        id: tabShadow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.top
        }
        source: "assets/toolbar-dropshadow.png"
        fillMode: Image.TileHorizontally
        asynchronous: true
    }

    states: [
        State {
            name: "hidden"
            PropertyChanges {
                target: toolbar
                y: toolbar.parent.height
            }
        },
        State {
            name: "shown"
            PropertyChanges {
                target: toolbar
                y: toolbar.parent.height - toolbar.height
            }
        }
    ]

    state: "shown"

    readonly property bool isFullyShown: y == (parent.height - height)

    Behavior on y {
        UbuntuNumberAnimation {
            duration: UbuntuAnimation.BriskDuration
        }
    }

    MouseArea {
        anchors.fill: parent
        // do not propagate click events to items below
    }
}
