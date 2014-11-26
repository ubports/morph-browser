/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 1.1
import webbrowsercommon.private 0.1

Item {
    property alias source: fetcher.url
    property bool fallbackIcon: true

    width: units.dp(16)
    height: units.dp(16)

    Image {
        id: image
        source: fetcher.localUrl
        anchors.fill: parent
    }

    FaviconFetcher {
        id: fetcher
    }

    Icon {
        anchors.fill: parent
        name: "stock_website"
        visible: parent.fallbackIcon &&
                 ((image.status !== Image.Ready) || !image.source.toString())
    }
}
