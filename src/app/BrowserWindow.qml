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

import QtQuick 2.0
import QtQuick.Window 2.1
import Ubuntu.Components 1.1

Window {
    id: window

    property bool developerExtrasEnabled: false
    property bool forceFullscreen: false
    property var currentWebview: null

    contentOrientation: Screen.orientation

    width: 800
    height: 600

    QtObject {
        id: internal
        property int currentWindowState: Window.Windowed
    }

    Connections {
        target: window.currentWebview
        onFullscreenChanged: window.setFullscreen(window.currentWebview.fullscreen)
    }

    function setFullscreen(fullscreen) {
        if (!window.forceFullscreen) {
            if (fullscreen) {
                internal.currentWindowState = window.visibility
                window.visibility = Window.FullScreen
            } else {
                window.visibility = internal.currentWindowState
            }
        }
    }
}
