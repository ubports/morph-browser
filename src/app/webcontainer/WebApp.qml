/*
 * Copyright 2013-2015 Canonical Ltd.
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
import com.canonical.Oxide 1.5 as Oxide
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

    property alias webappName: webview.webappName
    property alias webappUrlPatterns: webview.webappUrlPatterns
    property alias popupRedirectionUrlPrefixPattern: webview.popupRedirectionUrlPrefixPattern
    property alias webviewOverrideFile: webview.webviewOverrideFile
    property alias blockOpenExternalUrls: webview.blockOpenExternalUrls
    property alias localUserAgentOverride: webview.localUserAgentOverride
    property alias dataPath: webview.dataPath
    property alias runningLocalApplication: webview.runningLocalApplication

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
        id: webviewContainer
        anchors.fill: parent

        WebappContainerWebview {
            id: webview
            objectName: "webview"

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height
            developerExtrasEnabled: webapp.developerExtrasEnabled
        }

        Loader {
            anchors {
                fill: webview
                topMargin: (!webapp.chromeless && chromeLoader.item.state == "shown") ? chromeLoader.item.height : 0
            }
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
                    y: webapp.currentWebview ? webview.currentWebview.locationBarController.offset : 0
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

        Binding {
            when: webapp.currentWebview && !webapp.chromeless
            target: webapp.currentWebview ? webapp.currentWebview.locationBarController : null
            property: 'height'
            value: webapp.currentWebview.visible ? chromeLoader.item.height : 0
        }

        ChromeController {
            webview: webapp.currentWebview
            forceHide: webapp.chromeless
            defaultMode: (formFactor == "desktop") ? Oxide.LocationBarController.ModeShown
                                                   : Oxide.LocationBarController.ModeAuto
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
}
