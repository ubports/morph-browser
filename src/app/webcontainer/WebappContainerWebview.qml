/*
 * Copyright 2014-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Window 2.2
import Ubuntu.Components 1.3
import Ubuntu.Unity.Action 1.1 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import "../actions" as Actions
import "../UrlUtils.js" as UrlUtils
import ".."

FocusScope {
    id: containerWebview

    property Window window

    property bool initialUrlLoaded: false
    property string url: ""
    property bool developerExtrasEnabled: false
    property string webappName: ""
    property var dataPath
    property var currentWebview: webappContainerWebViewLoader.item ?
                                     webappContainerWebViewLoader.item.currentWebview
                                   : null
    property var webappUrlPatterns
    property string localUserAgentOverride: ""
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property bool blockOpenExternalUrls: false
    property bool runningLocalApplication: false
    property bool wide: false
    property bool openExternalUrlInOverlay: false
    property bool popupBlockerEnabled: true

    signal samlRequestUrlPatternReceived(string urlPattern)
    signal themeColorMetaInformationDetected(string theme_color)

    onWideChanged: {
        if (webappContainerWebViewLoader.item
                && webappContainerWebViewLoader.item.wide !== undefined) {
            webappContainerWebViewLoader.item.wide = wide
        }
    }

    Component {
        id: mediaAccessDialogComponent
        MediaAccessDialog {
            objectName: "mediaAccessDialog"
        }
    }

    PopupWindowController {
        id: popupController
        objectName: "popupController"
        webappUrlPatterns: containerWebview.webappUrlPatterns
        mainWebappView: containerWebview.currentWebview
        blockOpenExternalUrls: containerWebview.blockOpenExternalUrls
        mediaAccessDialogComponent: mediaAccessDialogComponent
        wide: containerWebview.wide
        onInitializeOverlayViewsWithUrls: {
            if (webappContainerWebViewLoader.item) {
                for (var i in urls) {
                    webappContainerWebViewLoader
                        .item
                        .openOverlayForUrl(urls[i])
                }
            }
        }

    }

    Connections {
        target: webappContainerWebViewLoader.item
        onSamlRequestUrlPatternReceived: {
            samlRequestUrlPatternReceived(urlPattern)
        }

        onThemeColorMetaInformationDetected: {
            themeColorMetaInformationDetected(theme_color)
        }

        onLastLoadSucceededChanged: {
          if (! initialUrlLoaded && webappContainerWebViewLoader.item.lastLoadSucceeded) {
             if (UrlUtils.extractScheme(containerWebView.url) !== 'file') {
               webappContainerWebViewLoader.item.runJavaScript("window.location.replace('%1')".arg(containerWebView.url))
             }
             initialUrlLoaded = true
          }
        }
    }

    Loader {
        id: webappContainerWebViewLoader
        objectName: "containerWebviewLoader"
        anchors.fill: parent
        focus: true
    }

    onUrlChanged: if (webappContainerWebViewLoader.item) webappContainerWebViewLoader.item.url = url

    Component.onCompleted: {
        var webappEngineSource = Qt.resolvedUrl("WebViewImplOxide.qml");

        // This is an experimental, UNSUPPORTED, API
        // It loads an alternative webview, adjusted for a specific webapp
        if (webviewOverrideFile.toString()) {
            console.log("Loading custom webview from " + webviewOverrideFile);
            webappEngineSource = webviewOverrideFile;
        }

        webappContainerWebViewLoader.setSource(
                    webappEngineSource,
                    { window: containerWebView.window
                    , localUserAgentOverride: containerWebview.localUserAgentOverride
                    , url: (UrlUtils.extractScheme(containerWebview.url) === 'file') ? containerWebview.url : 'about:blank'
                    , webappName: containerWebview.webappName
                    , dataPath: dataPath
                    , webappUrlPatterns: containerWebview.webappUrlPatterns
                    , developerExtrasEnabled: containerWebview.developerExtrasEnabled
                    , popupRedirectionUrlPrefixPattern: containerWebview.popupRedirectionUrlPrefixPattern
                    , blockOpenExternalUrls: containerWebview.blockOpenExternalUrls
                    , runningLocalApplication: containerWebview.runningLocalApplication
                    , popupController: popupController
                    , overlayViewsParent: containerWebview.parent
                    , wide: containerWebview.wide
                    , mediaAccessDialogComponent: mediaAccessDialogComponent
                    , openExternalUrlInOverlay: containerWebview.openExternalUrlInOverlay
                    , popupBlockerEnabled: containerWebview.popupBlockerEnabled})
    }
}

