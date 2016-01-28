/*
 * Copyright 2015-2016 Canonical Ltd.
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
import com.canonical.Oxide 1.7 as Oxide

Item {
    visible: false

    property var webview
    property bool forceHide: false
    property bool forceShow: false
    property int defaultMode: internal.modeAuto

    onWebviewChanged: internal.updateVisibility()
    onForceHideChanged: internal.updateVisibility()
    onForceShowChanged: internal.updateVisibility()

    QtObject {
        id: internal

        readonly property int modeAuto: Oxide.LocationBarController.ModeAuto
        readonly property int modeShown: Oxide.LocationBarController.ModeShown
        readonly property int modeHidden: Oxide.LocationBarController.ModeHidden

        function updateVisibility() {
            if (!webview) {
                return
            }
            webview.locationBarController.animated = false
            if (forceHide) {
                webview.locationBarController.mode = internal.modeHidden
            } else if (forceShow) {
                webview.locationBarController.mode = internal.modeShown
            } else if (!webview.fullscreen) {
                webview.locationBarController.mode = defaultMode
                if (webview.locationBarController.mode == internal.modeAuto) {
                    webview.locationBarController.show(false)
                }
            }
            webview.locationBarController.animated = true
        }
    }

    Connections {
        target: webview

        onFullscreenChanged: {
            if (webview.fullscreen) {
                webview.locationBarController.mode = internal.modeHidden
            } else if (!forceHide) {
                if (forceShow) {
                    webview.locationBarController.mode = internal.modeShown
                } else {
                    webview.locationBarController.mode = defaultMode
                    if (webview.locationBarController.mode == internal.modeAuto) {
                        webview.locationBarController.show(true)
                    }
                }
            }
        }

        onLoadingStateChanged: {
            if (webview.loading && !webview.fullscreen && !forceHide && !forceShow &&
                (webview.locationBarController.mode == internal.modeAuto)) {
                webview.locationBarController.show(true)
            }
        }

        onLoadEvent: {
            // When loading, force ModeShown until the load is committed or stopped,
            // to work around https://launchpad.net/bugs/1453908.
            if (forceHide || forceShow) return
            if (event.type == Oxide.LoadEvent.TypeStarted) {
                webview.locationBarController.mode = internal.modeShown
            } else if ((event.type == Oxide.LoadEvent.TypeCommitted) ||
                       (event.type == Oxide.LoadEvent.TypeStopped)) {
                webview.locationBarController.mode = defaultMode
            }
        }
    }
}
