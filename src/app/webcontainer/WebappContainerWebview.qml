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
    property bool developerExtrasEnabled: false
    property string webappName: ""
    property var currentWebview: webappContainerWebViewLoader.item
    property var toolbar: null
    property var webappUrlPatterns

    Loader {
        id: webappContainerWebViewLoader
        anchors.fill: parent
        source: withOxide ? Qt.resolvedUrl("WebViewImplOxide.qml") : Qt.resolvedUrl("ViewImplWebkit.qml")
        onLoaded: {
            webappContainerWebViewLoader.item.toolbar = containerWebview.toolbar
            webappContainerWebViewLoader.item.url = containerWebview.url
            webappContainerWebViewLoader.item.webappName = containerWebview.webappName
            webappContainerWebViewLoader.item.webappUrlPatterns = containerWebview.webappUrlPatterns
            webappContainerWebViewLoader.item.developerExtrasEnabled = containerWebview.developerExtrasEnabled
        }
    }
}
