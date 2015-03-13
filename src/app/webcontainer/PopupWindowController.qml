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
import Ubuntu.Components.Popups 1.0

Item {
    id: controller

    property var webappUrlPatterns
    property var mainWebappView
    property var views: []
    property bool blockOpenExternalUrls: false

    signal openExternalUrlTriggered(string url)

    readonly property int maxSimultaneousViews: 3

    function openUrlExternally(url) {
        if (!blockOpenExternalUrls) {
            console.log('deded ' + url)
            Qt.openUrlExternally(url)
        }
        openExternalUrlTriggered(url)
    }

    function handleNewViewAdded(view) {
        updateMainViewVisibility(false)

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
            return
        }
        var topView = views[views.length-1]
        if (topView !== view) {
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
            updateMainViewVisibility(true)
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
    function updateMainViewVisibility(visible) {
        if (mainWebappView) {
            mainWebappView.visible = visible
        }
    }

    Component {
        id: popupWebOverlayFactory
        PopupWindowOverlay {
            id: overlay

            height: parent.height
            width: parent.width

            NumberAnimation on y {
                from: overlay.parent.height
                to: 0
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
    }

    function handleNewForegroundNavigationRequest(
            url, request, isRequestFromMainWebappWebview) {

        if (views.length >= maxSimultaneousViews) {
            request.action = Oxide.NavigationRequest.ActionReject
            // Default to open externally, maybe should present a dialog
            openUrlExternally(url.toString())
            console.log("Maximum number of popup overlay opened, opening: "
                        + url
                        + " in the browser")
            return
        }
        request.action = Oxide.NavigationRequest.ActionAccept
    }
}
