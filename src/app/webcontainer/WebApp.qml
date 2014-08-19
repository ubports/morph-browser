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
import Ubuntu.Components 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
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

        ErrorSheet {
            anchors.fill: webview
            visible: webview.currentWebview && webview.currentWebview.lastLoadFailed
            url: webview.currentWebview.url
            onRefreshClicked: {
                if (webview.currentWebview)
                    webview.currentWebview.reload()
            }
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

        ScrollTracker {
            webview: webapp.oxide ? webapp.currentWebview : null
            header: webapp.chromeless ? null : chromeLoader.item

            active: !webapp.chromeless && !webapp.currentWebview.fullscreen
            onScrolledUp: chromeLoader.item.state = "shown"
            onScrolledDown: {
                if (nearBottom) {
                    chromeLoader.item.state = "shown"
                } else if (!nearTop) {
                    chromeLoader.item.state = "hidden"
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
}
