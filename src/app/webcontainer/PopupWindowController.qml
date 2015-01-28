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

Item {
    id: controller

    property var webappUrlPatterns
    property var mainWebappView
    property var views: []

    function onViewOpened(view) {
        mainWebappView.visible = false
        if (views.length !== 0) {
            var topView = views[views.length-1]
            topView.visible = false
        }
        view.visible = true
        views.push(view)
    }
    function onOpenInBrowser(url, view) {
        onViewClosed(view)
        Qt.openUrlExternally(url)
    }
    function onViewClosed(view) {
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
              popupWindowController: controller,
              width: parentView.width,
              height: parentView.height });
        onViewOpened(view)
    }

    Component {
        id: popupWebOverlayFactory
        PopupWindowOverlay {
            anchors.fill: parent

            NumberAnimation on width { to: 50; duration: 1000 }
        }
    }

    function handleNewForegroundNavigationRequest(
            url, webview, request, isRequestFromMainWebappWebview) {
        request.action = Oxide.NavigationRequest.ActionAccept
    }
}
