/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3

Item {
    id: tabChrome
    property alias title: tabItem.title
    property alias icon: tabItem.icon
    property alias incognito: tabItem.incognito
    property alias tabWidth: tabItem.width

    signal selected()
    signal closed()

    height: units.gu(4)

    Item {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(5)
        clip: true

        BorderImage {
            // We are basically splitting the shadow asset in two parts.
            // The left side is never scaled and it stays fixed below the
            // tab itself (with 4dp of the shadow poking out at the sides).
            // The right side will scale across the remaining width of the
            // component (which is empty and lets the previous preview show
            // through)
            border {
                left: tabWidth + units.dp(4)
            }
            anchors.fill: parent
            anchors.bottomMargin: - units.gu(3)
            height: units.gu(8)
            source: "assets/tab-shadow-narrow.png"
            opacity: 0.5
        }
    }

    TabItem {
        id: tabItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        hoverable: false
        onSelected: tabChrome.selected()
        onClosed: tabChrome.closed()
    }
}
