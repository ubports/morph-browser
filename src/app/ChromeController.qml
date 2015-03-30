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

import QtQuick 2.0
import com.canonical.Oxide 1.5 as Oxide

Item {
    visible: false

    property var webview
    property bool chromeless: false
    property bool forceHide: false

    readonly property int mode: {
        if (chromeless || forceHide) {
            return Oxide.LocationBarController.ModeHidden
        } else if (internal.forceShow) {
            return Oxide.LocationBarController.ModeShown
        } else if (webview.fullscreen) {
            return Oxide.LocationBarController.ModeHidden
        } else {
            return Oxide.LocationBarController.ModeAuto
        }
    }

    // Work around the lack of a show() method on the location bar controller
    // (https://launchpad.net/bugs/1422920) by forcing its mode to ModeShown
    // for long enough (500ms) to allow the animation to be committed.
    QtObject {
        id: internal
        property bool forceShow: false
    }
    Timer {
        id: delayedResetMode
        interval: 500
        onTriggered: internal.forceShow = false
    }
    Connections {
        target: webview
        onFullscreenChanged: {
            if (!webview.fullscreen) {
                internal.forceShow = true
                delayedResetMode.restart()
            }
        }
        onLoadingChanged: {
            if (webview.loading) {
                internal.forceShow = true
                delayedResetMode.restart()
            }
        }
    }
}
