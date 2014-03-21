/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.1
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Ubuntu.Components.Popups 0.1
import "../actions" as Actions
import ".."

UbuntuWebView {
    id: webview

    property var currentWebview: webview
    property var toolbar: null

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

    experimental.onPermissionRequested: {
        if (permission.type === PermissionRequest.Geolocation) {
            if (webview.toolbar) {
                webview.toolbar.close()
            }
            var text = i18n.tr("This page wants to know your device’s location.")
            PopupUtils.open(Qt.resolvedUrl("PermissionRequest.qml"),
                            webview.currentWebview,
                            {"permission": permission, "text": text})
        }
        // TODO: handle other types of permission requests
        // TODO: we might want to store the answer to avoid requesting
        //       the permission everytime the user visits this site.
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

    property int lastLoadRequestStatus: -1
    onLoadingChanged: lastLoadRequestStatus = loadRequest.status
}
