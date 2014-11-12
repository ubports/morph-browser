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
import Ubuntu.Unity.Action 1.1 as UnityActions
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
    property bool runningLocalApplication: webview.runningLocalApplication

    property string localUserAgentOverride: ""

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

    function getLocalUserAgentOverrideIfAny() {
        if (localUserAgentOverride.length !== 0)
            return localUserAgentOverride

        if (webappName && unityWebapps.model.exists(webappName))
            return unityWebapps.model.userAgentOverrideFor(webappName)

        return ""
    }

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
            runningLocalApplication: webapp.runningLocalApplication
            localUserAgentOverride: getLocalUserAgentOverrideIfAny()
        }

        Loader {
            anchors.fill: webview
            sourceComponent: ErrorSheet {
                visible: webview.currentWebview && webview.currentWebview.lastLoadFailed
                url: webview.currentWebview ? webview.currentWebview.url : ""
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
        injectExtraUbuntuApis: runningLocalApplication
        injectExtraContentShareCapabilities: !runningLocalApplication
    }

    function isValidContainedUrl(url) {
        if (!url || url.length === 0 || url === 'about:blank') {
            return false
        }
        if (popupRedirectionUrlPrefix.length !== 0
                && url.indexOf(popupRedirectionUrlPrefix) === 0) {
            return false
        }
        return true
    }
}
