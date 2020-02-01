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

Item {
    id: tabChrome
    property alias title: tabItem.title
    property alias icon: tabItem.icon
    property alias incognito: tabItem.incognito
    property alias tabWidth: tabItem.width

    signal selected()
    signal closed()

    height: units.gu(4)

    Image {
        anchors {
            fill: tabItem
            topMargin: - units.dp(4)
            bottomMargin: - units.dp(4)
            rightMargin: - units.dp(2)
            leftMargin: - units.dp(2)
        }
        source: "assets/tab-shadow-narrow.png"
        asynchronous: true
    }

    TabItem {
        id: tabItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        active: true
        hoverable: false
        fgColor: theme.palette.normal.backgroundText

        onSelected: tabChrome.selected()
        onClosed: tabChrome.closed()
    }
}
