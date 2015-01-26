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

    function createPopupView(request, from, context) {
        popupWebOverlayFactory.createObject(
            controller.parent,
            { request: request, webContext: context, width: 500, height: 800 });
    }

    Component {
        id: popupWebOverlayFactory
        PopupWindowOverlay {
            anchors {
                fill: controller.parent
            }
        }
    }

    function shouldAllowNavigationTo(url) {
        if (! webappUrlPatterns || webappUrlPatterns.length === 0) {
            return true
        }
        // We still take the possible additional patterns specified in the command line
        // (the in the case of finer grained ones specifically for the container and not
        // as an 'install source' for the webapp).
        for (var i = 0; i < webappUrlPatterns.length; ++i) {
            var pattern = webappUrlPatterns[i]
            if (url.match(pattern)) {
                return true;
            }
        }
        return false;
    }

    function handleNewForegroundNavigationRequest(
            url, webview, request, isRequestFromMainWebappWebview) {
        var targetUrl = url.toString();
        if (targetUrl === 'about:blank') {
            console.log('Accepting a new window request to navigate to "about:blank"')
            request.action = Oxide.NavigationRequest.ActionAccept
            return
        }

        if (!shouldAllowNavigationTo(targetUrl)) {
            if (!isRequestFromMainWebappWebview) {
                console.debug('Redirecting popup browsing ' + targetUrl + ' in the current container window.')
                request.action = Oxide.NavigationRequest.ActionReject
                webappContainerHelper.browseToUrlRequested(webview, targetUrl)
                return
            }
        }
    }
}
