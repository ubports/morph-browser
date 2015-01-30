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
import com.canonical.Oxide 1.0 as Oxide
import Ubuntu.Components 1.1

Item {
    id: controller

    property var webappUrlPatterns
    property var mainWebappView
    property var views: []
    property bool blockOpenExternalUrls: false

    signal openExternalUrlTriggered(string url)

    function openUrlExternally(url) {
        if (blockOpenExternalUrls) {
            Qt.openUrlExternally(url)
        }
        openExternalUrlTriggered(url)
    }

    function handleNewViewAdded(view) {
        if (mainWebappView) {
            mainWebappView.visible = false
        }

        if (views.length !== 0) {
            var topView = views[views.length-1]
            topView.visible = false
        }

        view.visible = true
        views.push(view)
    }
    function handleOpenInUrlBrowserForView(url, view) {
        handleViewRemoved(view)
        openExternalUrlTriggered(url)
        openUrlExternally(url)
    }
    function handleViewRemoved(view) {
        if (views.length === 0) {
            console.error("Invalid view list")
            return
        }
        var topView = views[views.length-1]
        if (topView !== view) {
            console.error("Invalid top view")
            return
        }
        topView.visible = false

        // TODO Oxide prepareToClose & prepareToCloseResponse
        topView.destroy()
        views.pop()

        if (views.length !== 0) {
            views[views.length-1].visible = true
        }
        else {
            mainWebappView.visible = true
        }
    }
    function createPopupView(parentView, request, isRequestFromMainWebappWebview, context) {
        var view = popupWebOverlayFactory.createObject(
            parentView,
            { request: request,
              webContext: context,
              popupWindowController: controller });
        handleNewViewAdded(view)
    }

    Component {
        id: popupWebOverlayFactory
        PopupWindowOverlay {
            anchors.fill: parent
        }
    }

    function handleNewForegroundNavigationRequest(
            url, webview, request, isRequestFromMainWebappWebview) {
        request.action = Oxide.NavigationRequest.ActionAccept
    }
}
