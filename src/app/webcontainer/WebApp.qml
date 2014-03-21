/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import "../actions" as Actions
import ".."

BrowserView {
    id: webapp

    currentWebview: webview.currentWebview

    property alias oxide: webview.withOxide
    property string url: ""
    property string webappName: ""
    property string webappModelSearchPath: ""
    property var webappUrlPatterns: null

    actions: [
        Actions.Back {
            enabled: backForwardButtonsVisible && webview.currentWebview && webview.currentWebview.canGoBack
            onTriggered: webview.goBack()
        },
        Actions.Forward {
            enabled: backForwardButtonsVisible && webview.currentWebview && webview.currentWebview.canGoForward
            onTriggered: webview.goForward()
        },
        Actions.Reload {
            onTriggered: webview.reload()
        }
    ]

    Page {
        anchors.fill: parent

        // Work around https://bugs.launchpad.net/webbrowser-app/+bug/1270848 and
        // https://bugs.launchpad.net/ubuntu/+source/webbrowser-app/+bug/1271436.
        // The UITK is trying too hard to be clever about the header and toolbar.
        flickable: null

        WebappContainerWebview {
            id: webview
            toolbar: panel.panel
            url: webapp.url

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height
        }

        ErrorSheet {
            anchors.fill: webview
            visible: {
                if (webview.lastLoadFailed !== undefined)
                    return webview.lastLoadFailed
                return webview.currentWebview && webview.currentWebview.lastLoadFailed
            }
            url: webview.currentWebview.url
            onRefreshClicked: webview.reload()
        }
    }

    PanelLoader {
        id: panel

        currentWebview: webview.currentWebview
        chromeless: webapp.chromeless

        backForwardButtonsVisible: webapp.backForwardButtonsVisible
        activityButtonVisible: false
        addressBarVisible: webapp.addressBarVisible

        anchors {
            left: parent.left
            right: parent.right
            bottom: panel.opened ? osk.top : parent.bottom
        }
    }

    UnityWebApps.UnityWebApps {
        id: unityWebapps
        name: webappName
        bindee: webview.currentWebview
        actionsContext: actionManager.globalContext
        model: UnityWebApps.UnityWebappsAppModel { searchPath: webappModelSearchPath }
    }

    function isRunningAsANamedWebapp() {
        return webappName && typeof(webappName) === 'string' && webappName.length != 0
    }
}
