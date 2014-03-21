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
import Ubuntu.Components 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import "../actions" as Actions
import ".."

Item {
    id: containerWebview

    property string url: ""
    property bool withOxide: false
    property string webappName: ""
    property var currentWebview: webappContainerWebViewLoader.item
    property var toolbar: null

    function isRunningAsANamedWebapp() {
        return false;
    }

    Loader {
        id: webappContainerWebViewLoader
        anchors.fill: parent
        sourceComponent: withOxide ? webappContainerWebViewOxide : webappContainerWebViewWebkit
    }

    Component {
        id: webappContainerWebViewWebkit

        WebViewImplWebkit {
            id: webview
            property var toolbar: containerWebview.toolbar
            url: containerWebview.url
            webappName: containerWebview.webappName
        }
    }

    Component {
        id: webappContainerWebViewOxide

        WebViewImpl {
            id: webview

            url: containerWebview.url
            currentWebview: webview
            toolbar: panel.panel

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

            /*function navigationRequestedDelegate(request) {
                if (!request.isMainFrame) {
                    request.action = WebView.AcceptRequest
                    return
                }

                var action = WebView.AcceptRequest
                var url = request.url.toString()

                // The list of url patterns defined by the webapp takes precedence over command line
                if (isRunningAsANamedWebapp()) {
                    if (unityWebapps.model.exists(unityWebapps.name) &&
                        !unityWebapps.model.doesUrlMatchesWebapp(unityWebapps.name, url)) {
                        action = WebView.IgnoreRequest
                    }
                } else if (webappUrlPatterns && webappUrlPatterns.length !== 0) {
                    action = WebView.IgnoreRequest
                    for (var i = 0; i < webappUrlPatterns.length; ++i) {
                        var pattern = webappUrlPatterns[i]
                        if (url.match(pattern)) {
                            action = WebView.AcceptRequest
                            break
                        }
                    }
                }

                request.action = action
                if (action === WebView.IgnoreRequest) {
                    Qt.openUrlExternally(url)
                }
            }*/

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
    }
}
