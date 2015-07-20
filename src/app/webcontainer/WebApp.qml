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
import Qt.labs.settings 1.0
import "../actions" as Actions
import ".."

BrowserView {
    id: webapp
    objectName: "webappBrowserView"

    currentWebview: webview.currentWebview

    property alias url: webview.url

    property bool accountSwitcher

    property string webappModelSearchPath: ""

    property alias webappName: webview.webappName
    property var webappUrlPatterns
    property alias popupRedirectionUrlPrefixPattern: webview.popupRedirectionUrlPrefixPattern
    property alias webviewOverrideFile: webview.webviewOverrideFile
    property alias blockOpenExternalUrls: webview.blockOpenExternalUrls
    property alias localUserAgentOverride: webview.localUserAgentOverride
    property alias dataPath: webview.dataPath
    property alias runningLocalApplication: webview.runningLocalApplication

    property bool backForwardButtonsVisible: false
    property bool chromeVisible: false
    readonly property bool chromeless: !chromeVisible && !backForwardButtonsVisible && !accountSwitcher

    signal chooseAccount()

    // Used for testing. There is a bug that currently prevents non visual Qt objects
    // to be introspectable from AP which makes directly accessing the settings object
    // not possible https://bugs.launchpad.net/autopilot-qt/+bug/1273956
    property alias generatedUrlPatterns: urlPatternSettings.generatedUrlPatterns

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

    Settings {
        id: urlPatternSettings
        property string generatedUrlPatterns
    }

    function addGeneratedUrlPattern(urlPattern) {
        var patterns
        try {
            patterns = JSON.parse(urlPatternSettings.generatedUrlPatterns)
        } catch(e) {
            console.error("Invalid JSON content found in url patterns file")
        }
        if (! (patterns instanceof Array)) {
            console.error("Invalid JSON content type found in url patterns file (not an array)")
            patterns = []
        }
        if (patterns.indexOf(urlPattern) < 0) {
            patterns.push(urlPattern)

            urlPatternSettings.generatedUrlPatterns = JSON.stringify(patterns)
        }
    }

    function mergeUrlPatternSets(p1, p2) {
        if ( ! (p1 instanceof Array)) {
            return (p2 instanceof Array) ? p2 : []
        }
        if ( ! (p2 instanceof Array)) {
            return (p1 instanceof Array) ? p1 : []
        }
        var p1hash = {}
        var result = []
        for (var i1 in p1) {
            p1hash[p1[i1]] = 1
            result.push(p1[i1])
        }
        for (var i2 in p2) {
            if (! (p2[i2] in p1hash)) {
                result.push(p2[i2])
            }
        }
        return result
    }

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
            onSamlRequestUrlPatternReceived: {
                addGeneratedUrlPattern(urlPattern)
            }
            webappUrlPatterns: mergeUrlPatternSets(urlPatternSettings.generatedUrlPatterns,
                                   webapp.webappUrlPatterns)
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
                    accountSwitcher: webapp.accountSwitcher

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(6)
                    y: webapp.currentWebview ? webview.currentWebview.locationBarController.offset : 0

                    onChooseAccount: webapp.chooseAccount()
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
