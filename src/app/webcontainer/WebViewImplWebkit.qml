/*
 * Copyright 2013-2014 Canonical Ltd.
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
import QtWebKit 3.1
import QtWebKit.experimental 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Extras.Browser 0.1
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Ubuntu.Components.Popups 1.0
import "../actions" as Actions
import ".."

UbuntuWebView {
    id: webview

    property bool developerExtrasEnabled: false
    property var currentWebview: webview
    property string webappName: ""
    property var webappUrlPatterns: null
    property string localUserAgentOverride: ""
    property string popupRedirectionUrlPrefixPattern: ""
    property url dataPath // unused
    property bool runningLocalApplication: false

    function getUAString() {
        return webview.localUserAgentOverride.length === 0 ? undefined : webview.localUserAgentOverride
    }

    experimental.certificateVerificationDialog: CertificateVerificationDialog {}
    experimental.authenticationDialog: AuthenticationDialog {}
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {}
    experimental.alertDialog: AlertDialog {}
    experimental.confirmDialog: ConfirmDialog {}
    experimental.promptDialog: PromptDialog {}

    selectionActions: ActionList {
        Actions.Copy {
            onTriggered: selection.copy()
        }
    }

    StateSaver.properties: "url"
    StateSaver.enabled: true

    property bool lastLoadFailed: false
    onLoadingChanged: {
        lastLoadFailed = (loadRequest.status === WebView.LoadFailedStatus)
    }

    experimental.preferences.developerExtrasEnabled: developerExtrasEnabled

    experimental.onPermissionRequested: {
        if (permission.type === PermissionRequest.Geolocation) {
            var text = i18n.tr("This page wants to know your device’s location.")
            PopupUtils.open(Qt.resolvedUrl("../PermissionRequest.qml"),
                            webview.currentWebview,
                            {"permission": permission, "text": text})
        }
        // TODO: handle other types of permission requests
        // TODO: we might want to store the answer to avoid requesting
        //       the permission everytime the user visits this site.
    }

    contextualActions: ActionList {
        Actions.CopyLink {
            enabled: webview.contextualData.href.toString()
            onTriggered: Clipboard.push([webview.contextualData.href])
        }
        Actions.CopyImage {
            enabled: webview.contextualData.img.toString()
            onTriggered: Clipboard.push([webview.contextualData.img])
        }
    }

    function isRunningAsANamedWebapp() {
        return webview.webappName && typeof(webview.webappName) === 'string' && webview.webappName.length != 0
    }

    function haveValidUrlPatterns() {
        return webappUrlPatterns && webappUrlPatterns.length !== 0
    }

    function shouldAllowNavigationTo(url) {
        // The list of url patterns defined by the webapp takes precedence over command line
        if (isRunningAsANamedWebapp()) {
            if (unityWebapps.model.exists(unityWebapps.name) &&
                unityWebapps.model.doesUrlMatchesWebapp(unityWebapps.name, url)) {
                return true;
            }
        }

        // We still take the possible additional patterns specified in the command line
        // (the in the case of finer grained ones specifically for the container and not
        // as an 'install source' for the webapp).
        if (webappUrlPatterns && webappUrlPatterns.length !== 0) {
            for (var i = 0; i < webappUrlPatterns.length; ++i) {
                var pattern = webappUrlPatterns[i]
                if (url.match(pattern)) {
                    return true;
                }
            }
        }

        return false;
    }

    function navigationRequestedDelegate(request) {
        if (!request.isMainFrame) {
            request.action = WebView.AcceptRequest
            return
        }

        // Pass-through if we are not running as a named webapp (--webapp='Gmail')
        // or if we dont have a list of url patterns specified to filter the
        // browsing actions
        if ( ! haveValidUrlPatterns() && ! isRunningAsANamedWebapp()) {
            request.action = WebView.AcceptRequest
            return
        }

        var action = WebView.IgnoreRequest
        var url = request.url.toString()

        if (shouldAllowNavigationTo(url)) {
            request.action = WebView.AcceptRequest
            return;
        }

        request.action = action
        if (action === WebView.IgnoreRequest) {
            console.debug('Opening: ' + url + ' in the browser window.')
            Qt.openUrlExternally(url)
        }
    }

    onNewTabRequested: Qt.openUrlExternally(url)

    // Small shim needed when running as a webapp to wire-up connections
    // with the webview (message received, etc…).
    // This is being called (and expected) internally by the webapps
    // component as a way to bind to a webview lookalike without
    // reaching out directly to its internals (see it as an interface).
    function getUnityWebappsProxies() {
        var eventHandlers = {
            onAppRaised: function () {
                if (webbrowserWindow) {
                    try {
                        webbrowserWindow.raise();
                    } catch (e) {
                        console.debug('Error while raising: ' + e);
                    }
                }
            }
        };
        return UnityWebAppsUtils.makeProxiesForQtWebViewBindee(webview, eventHandlers)
    }
}
