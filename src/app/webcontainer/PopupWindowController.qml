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

    // Used to access runtime behavior during tests
    signal openExternalUrlTriggered(string url)
    signal newViewCreated(string url)
    signal windowOverlayAnimationDone()

    readonly property int maxSimultaneousViews: 3

    function openUrlExternally(url) {
        if (!blockOpenExternalUrls) {
            Qt.openUrlExternally(url)
        }
        openExternalUrlTriggered(url)
    }

    function onOverlayMoved(popup, diffY) {
        if ((popup.y + diffY) > 0) {
            popup.y += diffY
        }
    }
    function handleNewViewAdded(view) {
        if (views.length !== 0) {
            var topView = views[views.length-1]
        }
        views.push(view)
    }
    function handleOpenInUrlBrowserForView(url, view) {
        handleViewRemoved(view)
        openExternalUrlTriggered(url)
        openUrlExternally(url)
    }
    function topViewOnStack() {
        if (views.length !== 0) {
            return views[views.length-1]
        }
        return mainWebappView
    }
    function handleViewRemoved(view) {
        if (views.length === 0) {
            return
        }

        var topMostView = views[views.length-1]
        if (topMostView !== view) {
            return
        }
        views.pop()

        var parentHeight = topMostView.parent.height
        var nextView = topViewOnStack()
        nextView.visible = true

        function onViewSlidingOut() {
            if (topMostView.y >= (topMostView.parent.height - 10)) {
                topMostView.yChanged.disconnect(onViewSlidingOut)
                topMostView.destroy()

                updateViewVisibility(nextView, true)
            } else {
                if (nextView) {
                    nextView.opacity = 1.0 - (parentHeight - topMostView.y) / parentHeight
                }
            }
        }
        topMostView.yChanged.connect(onViewSlidingOut)
        topMostView.y = topMostView.parent.height
    }
    function createPopupView(parentView, request, isRequestFromMainWebappWebview, context) {
        var view = popupWebOverlayFactory.createObject(
            parentView,
            { request: request,
              webContext: context,
              popupWindowController: controller });

        var topMostView = topViewOnStack()

        function onViewSlidingIn() {
            var parentHeight = view.parent.height

            if (view.y <= 10) {
                view.yChanged.disconnect(onViewSlidingIn)

                updateViewVisibility(topMostView, false)
            } else {
                if (topMostView) {
                    topMostView.opacity = view.y / parentHeight
                }
            }
        }
        view.yChanged.connect(onViewSlidingIn)

        view.y = 0
        handleNewViewAdded(view)
        newViewCreated(view.url)
    }
    function updateViewVisibility(view, visible) {
        if (view) {
            view.opacity = visible ? 1.0 : 0.0
            view.visible = visible
        }
    }

    Component {
        id: popupWebOverlayFactory
        PopupWindowOverlay {
            id: overlay

            height: parent.height
            width: parent.width

            y: overlay.parent.height

            Behavior on y {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                    onRunningChanged: {
                        if (! running) {
                            windowOverlayAnimationDone()
                        }
                    }
                }
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
