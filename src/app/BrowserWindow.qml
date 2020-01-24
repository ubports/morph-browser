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
import QtQuick.Window 2.2
import QtSystemInfo 5.0
import Ubuntu.Components 1.3

Window {
    id: window

    property bool developerExtrasEnabled: false
    property bool forceFullscreen: false
    property var currentWebview: null
    property bool hasTouchScreen: false

    contentOrientation: Screen.orientation

    minimumWidth: units.gu(40)
    minimumHeight: units.gu(20)

    width: units.gu(100)
    height: units.gu(75)

    QtObject {
        id: internal
        property int currentWindowState: Window.Windowed
    }

    ScreenSaver {
        id: screenSaver
        screenSaverEnabled: ! ( window.active && window.currentWebview && (window.currentWebview.isFullScreen || window.currentWebview.recentlyAudible) )
    }

    Connections {
        target: window.currentWebview
        onIsFullScreenChanged: window.setFullscreen(window.currentWebview.isFullScreen)
    }

    function setFullscreen(fullscreen) {
        if (!window.forceFullscreen) {
            if (fullscreen) {
                if (window.visibility != Window.FullScreen) {
                    internal.currentWindowState = window.visibility
                    window.visibility = Window.FullScreen
                }
            } else {
                window.visibility = internal.currentWindowState
            }
        }
    }
}
