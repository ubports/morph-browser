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
import Ubuntu.Components 1.1
import Ubuntu.Unity.Action 1.0 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import webbrowsercommon.private 0.1
import "../actions" as Actions
import ".."

BrowserView {
    id: webapp
    objectName: "webappBrowserView"

    currentWebview: webview.currentWebview

    property alias url: webview.url

    property string webappModelSearchPath: ""

    property alias oxide: webview.withOxide
    property alias webappName: webview.webappName
    property alias webappUrlPatterns: webview.webappUrlPatterns
    property alias popupRedirectionUrlPrefix: webview.popupRedirectionUrlPrefix
    property alias webviewOverrideFile: webview.webviewOverrideFile

    property bool backForwardButtonsVisible: false
    property bool chromeVisible: false
    readonly property bool chromeless: !chromeVisible && !backForwardButtonsVisible

    actions: [
        Actions.Back {
            enabled: webapp.backForwardButtonsVisible && webview.currentWebview && webview.currentWebview.canGoBack
            onTriggered: webview.currentWebview.goBack()
        },
        Actions.Forward {
            enabled: webapp.backForwardButtonsVisible && webview.currentWebview && webview.currentWebview.canGoForward
            onTriggered: webview.currentWebview.goForward()
        },
        Actions.Reload {
            onTriggered: webview.currentWebview.reload()
        }
    ]

    Item {
        anchors.fill: parent

        WebappContainerWebview {
            id: webview

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: webapp.chromeless ? 0 : chromeLoader.item.visibleHeight
            }
            height: parent.height - osk.height - (webapp.chromeless ? 0 : chromeLoader.item.visibleHeight)
            developerExtrasEnabled: webapp.developerExtrasEnabled
            localUserAgentOverride: webappName && unityWebapps.model.exists(webappName) ?
                                      unityWebapps.model.userAgentOverrideFor(webappName) : ""
        }

        Loader {
            anchors.fill: webview
            sourceComponent: ErrorSheet {
                visible: webview.currentWebview && webview.currentWebview.lastLoadFailed
                url: webview.currentWebview.url
                onRefreshClicked: {
                    if (webview.currentWebview)
                        webview.currentWebview.reload()
                }
            }
            asynchronous: true
        }

        Loader {
            id: chromeLoader

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            sourceComponent: webapp.chromeless ? progressbarComponent : chromeComponent

            Component {
                id: chromeComponent

                Chrome {
                    webview: webapp.currentWebview
                    navigationButtonsVisible: webapp.backForwardButtonsVisible

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(6)

                    Connections {
                        target: webapp.currentWebview
                        ignoreUnknownSignals: true
                        onLoadingChanged: {
                            if (webapp.currentWebview.loading) {
                                chromeLoader.item.state = "shown"
                            } else if (webapp.currentWebview.fullscreen) {
                                chromeLoader.item.state = "hidden"
                            }
                        }
                        onFullscreenChanged: {
                            if (webapp.currentWebview.fullscreen) {
                                chromeLoader.item.state = "hidden"
                            } else {
                                chromeLoader.item.state = "shown"
                            }
                        }
                    }
                }
            }

            Component {
                id: progressbarComponent

                ThinProgressBar {
                    webview: webapp.currentWebview

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                }
            }
        }

        Loader {
            sourceComponent: (webapp.oxide && !webapp.chromeless) ? chromeStateTrackerComponent : undefined

            Component {
                id: chromeStateTrackerComponent

                ChromeStateTracker {
                    webview: webapp.currentWebview
                    header: chromeLoader.item
                }
            }
        }
    }

    UnityWebApps.UnityWebApps {
        id: unityWebapps
        name: webappName
        bindee: webview.currentWebview
        actionsContext: actionManager.globalContext
        model: UnityWebApps.UnityWebappsAppModel { searchPath: webappModelSearchPath }
    }

    SessionStorage {
        id: session

        dataFile: dataLocation + "/session.json"

        function save() {
            if (!locked) {
                return
            }
            if (webapp.currentWebview) {
                var state = serializeWebviewState(webapp.currentWebview)
                store(JSON.stringify(state))
            }
        }

        function restore() {
            if (!locked) {
                return
            }
            var state = null
            try {
                state = JSON.parse(retrieve())
            } catch (e) {
                return
            }
            if (state) {
                var url = state.url
                if (url) {
                    webapp.currentWebview.url = url
                }
            }
        }

        // This function is used to save the current state of a webview.
        // The current implementation is naive, it only saves the current URL.
        // In the future, we’ll want to rely on oxide to save and restore a full state
        // of the webview as a binary blob, which includes navigation history, current
        // scroll offset and form data. See http://pad.lv/1353143.
        function serializeWebviewState(webview) {
            var state = {}
            state.url = webview.url.toString()
            return state
        }
    }
    Connections {
        target: webapp.currentWebview
        onUrlChanged: {
            var url = webapp.currentWebview.url.toString()
            if (url.length === 0 || url === 'about:blank') {
                return;
            }
            if (popupRedirectionUrlPrefix.length !== 0
                    && url.indexOf(popupRedirectionUrlPrefix) === 0) {
                return;
            }
            session.save()
        }
    }
    Component.onCompleted: {
        if (webapp.restoreSession) {
            session.restore()
        }
    }
}
