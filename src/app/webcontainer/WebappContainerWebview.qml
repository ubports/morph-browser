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
import Ubuntu.Components 1.1
import Ubuntu.Unity.Action 1.1 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import "../actions" as Actions
import ".."

Item {
    id: containerWebview

    property string url: ""
    property bool withOxide: false
    property bool developerExtrasEnabled: false
    property string webappName: ""
    property url dataPath
    property var currentWebview: webappContainerWebViewLoader.item ?
                                     webappContainerWebViewLoader.item.currentWebview
                                   : null
    property var webappUrlPatterns
    property string localUserAgentOverride: ""
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property bool blockOpenExternalUrls: false
    property bool runningLocalApplication: false

    PopupWindowController {
        id: popupController
        objectName: "popupController"
        webappUrlPatterns: webappUrlPatterns
        mainWebappView: currentWebview
    }

    Loader {
        id: webappContainerWebViewLoader
        objectName: "containerWebviewLoader"
        anchors.fill: parent
    }

    onUrlChanged: if (webappContainerWebViewLoader.item) webappContainerWebViewLoader.item.url = url

    Component.onCompleted: {
        var webappEngineSource =
                withOxide ?
                    Qt.resolvedUrl("WebViewImplOxide.qml")
                  : Qt.resolvedUrl("WebViewImplWebkit.qml");

        // This is an experimental, UNSUPPORTED, API
        // It loads an alternative webview, adjusted for a specific webapp
        if (webviewOverrideFile.toString()) {
            console.log("Loading custom webview from " + webviewOverrideFile);
            webappEngineSource = webviewOverrideFile;
        }

        webappContainerWebViewLoader.setSource(
                    webappEngineSource,
                    { localUserAgentOverride: containerWebview.localUserAgentOverride
                    , url: containerWebview.url
                    , webappName: containerWebview.webappName
                    , dataPath: dataPath
                    , webappUrlPatterns: containerWebview.webappUrlPatterns
                    , developerExtrasEnabled: containerWebview.developerExtrasEnabled
                    , popupRedirectionUrlPrefixPattern: containerWebview.popupRedirectionUrlPrefixPattern
                    , blockOpenExternalUrls: containerWebview.blockOpenExternalUrls
                    , runningLocalApplication: containerWebview.runningLocalApplication
                    , popupController: popupController})
    }
}

