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

Item {
    property url source
    property bool fallbackIcon: true

    width: units.dp(16)
    height: units.dp(16)

    Image {
        id: image
        readonly property string url: parent.source.toString()

        // XXX: temporarily disable the use of the custom image provider until
        // we figure out a proper fix for https://launchpad.net/bugs/1395748
        // (see also https://bugreports.qt-project.org/browse/QTBUG-42875).
        //source: url ? "image://favicon/" + url : ""
        source: parent.source

        anchors.fill: parent
    }

    Icon {
        anchors.fill: parent
        name: "stock_website"
        visible: parent.fallbackIcon && (image.status !== Image.Ready)
    }
}
