/*
 * Copyright 2013-2016 Canonical Ltd.
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

import QtQuick 2.4
import webbrowsercommon.private 0.1
import com.canonical.Oxide 1.5 as Oxide
import Ubuntu.Components 1.3
import Ubuntu.Unity.Action 1.1 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Qt.labs.settings 1.0
import "../actions" as Actions
import ".."
import "ColorUtils.js" as ColorUtils

BrowserView {
    id: webapp
    objectName: "webappBrowserView"

    currentWebview: containerWebView.currentWebview

    property alias url: containerWebView.url

    property bool accountSwitcher

    property string webappModelSearchPath: ""

    property var webappUrlPatterns
    property alias popupRedirectionUrlPrefixPattern: containerWebView.popupRedirectionUrlPrefixPattern
    property alias webviewOverrideFile: containerWebView.webviewOverrideFile
    property alias blockOpenExternalUrls: containerWebView.blockOpenExternalUrls
    property alias localUserAgentOverride: containerWebView.localUserAgentOverride
    property alias dataPath: containerWebView.dataPath
    property alias runningLocalApplication: containerWebView.runningLocalApplication
    property alias openExternalUrlInOverlay: containerWebView.openExternalUrlInOverlay
    property alias popupBlockerEnabled: containerWebView.popupBlockerEnabled

    property string webappName: ""

    property bool backForwardButtonsVisible: false
    property bool chromeVisible: false
    readonly property bool chromeless: !chromeVisible && !backForwardButtonsVisible && !accountSwitcher
    readonly property real themeColorTextContrastFactor: 3.0

    signal chooseAccount()

    // Used for testing. There is a bug that currently prevents non visual Qt objects
    // to be introspectable from AP which makes directly accessing the settings object
    // not possible https://bugs.launchpad.net/autopilot-qt/+bug/1273956
    property alias generatedUrlPatterns: urlPatternSettings.generatedUrlPatterns

    actions: [
        Actions.Back {
            enabled: webapp.backForwardButtonsVisible && containerWebView.currentWebview && containerWebView.currentWebview.canGoBack
            onTriggered: containerWebView.currentWebview.goBack()
        },
        Actions.Forward {
            enabled: webapp.backForwardButtonsVisible && containerWebView.currentWebview && containerWebView.currentWebview.canGoForward
            onTriggered: containerWebView.currentWebview.goForward()
        },
        Actions.Reload {
            onTriggered: containerWebView.currentWebview.reload()
        }
    ]

    Settings {
        id: urlPatternSettings
        property string generatedUrlPatterns
    }

    function addGeneratedUrlPattern(urlPattern) {
        if (urlPattern.trim().length === 0) {
            return;
        }

        var patterns = []
        if (urlPatternSettings.generatedUrlPatterns
                && urlPatternSettings.generatedUrlPatterns.trim().length !== 0) {
            try {
                patterns = JSON.parse(urlPatternSettings.generatedUrlPatterns)
            } catch(e) {
                console.error("Invalid JSON content found in url patterns file")
            }
            if (! (patterns instanceof Array)) {
                console.error("Invalid JSON content type found in url patterns file (not an array)")
                patterns = []
            }
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
            id: containerWebView
            objectName: "webview"

            wide: webapp.wide
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height
            developerExtrasEnabled: webapp.developerExtrasEnabled

            onThemeColorMetaInformationDetected: {
                var color = webappContainerHelper.rgbColorFromCSSColor(theme_color)
                if (!webapp.chromeless && chromeLoader.item && color.length) {
                    chromeLoader.item.backgroundColor = theme_color
                    chromeLoader.item.chromeTextLabelColor =
                            ColorUtils.getMostConstrastedColor(
                                color,
                                Qt.darker(theme_color, themeColorTextContrastFactor),
                                Qt.lighter(theme_color, themeColorTextContrastFactor))
                }
            }
            onSamlRequestUrlPatternReceived: {
                addGeneratedUrlPattern(urlPattern)
            }
            webappUrlPatterns: mergeUrlPatternSets(urlPatternSettings.generatedUrlPatterns,
                                   webapp.webappUrlPatterns)

            /**
             * Use the --webapp parameter value w/ precedence, but also take into account
             * the fact that a webapp 'name' can come from a webapp-properties.json file w/o
             * being explictly defined here.
             */
            webappName: webapp.webappName === "" ? unityWebapps.name : webapp.webappName

            Loader {
                anchors {
                    fill: containerWebView
                    topMargin: (!webapp.chromeless && chromeLoader.item.state == "shown")
                               ? chromeLoader.item.height
                               : 0
                }
                active: containerWebView.currentWebview &&
                        (webProcessMonitor.crashed || (webProcessMonitor.killed && !containerWebView.currentWebview.loading))
                sourceComponent: SadPage {
                    webview: containerWebView.currentWebview
                    objectName: "mainWebviewSadPage"
                }
                WebProcessMonitor {
                    id: webProcessMonitor
                    webview: containerWebView.currentWebview
                }
                asynchronous: true
            }
        }

        Loader {
            anchors {
                fill: containerWebView
                topMargin: (!webapp.chromeless && chromeLoader.item.state == "shown") ? chromeLoader.item.height : 0
            }
            sourceComponent: ErrorSheet {
                visible: containerWebView.currentWebview && containerWebView.currentWebview.lastLoadFailed
                url: containerWebView.currentWebview ? containerWebView.currentWebview.url : ""
                onRefreshClicked: {
                    if (containerWebView.currentWebview)
                        containerWebView.currentWebview.reload()
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
                    y: webapp.currentWebview ? containerWebView.currentWebview.locationBarController.offset : 0

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
            defaultMode: webapp.hasTouchScreen
                             ? Oxide.LocationBarController.ModeAuto
                             : Oxide.LocationBarController.ModeShown
        }
    }

    UnityWebApps.UnityWebApps {
        id: unityWebapps
        name: webappName
        bindee: containerWebView.currentWebview
        embeddedUiComponentParent: webapp
        actionsContext: actionManager.globalContext
        model: UnityWebApps.UnityWebappsAppModel { searchPath: webappModelSearchPath }
        injectExtraUbuntuApis: runningLocalApplication
        injectExtraContentShareCapabilities: !runningLocalApplication
    }

    // F5 or Ctrl+R: Reload current Tab
    Shortcut {
        sequence: "Ctrl+r"
        enabled: currentWebview && currentWebview.visible
        onActivated: currentWebview.reload()
    }
    Shortcut {
        sequence: "F5"
        enabled: currentWebview && currentWebview.visible
        onActivated: currentWebview.reload()
    }

    // Alt+← or Backspace: Goes to the previous page
    Shortcut {
        sequence: StandardKey.Back
        enabled: currentWebview && currentWebview.canGoBack
        onActivated: currentWebview.goBack()
    }

    // Alt+→ or Shift+Backspace: Goes to the next page
    Shortcut {
        sequence: StandardKey.Forward
        enabled: currentWebview && currentWebview.canGoForward
        onActivated: currentWebview.goForward()
    }
}
