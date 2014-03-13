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
import com.canonical.Oxide 0.1
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.2
//import Ubuntu.Components.Popups 0.1
import "actions" as Actions

UbuntuWebView {
    id: webview

    property var currentWebview: webview
    property var toolbar: null
    property QtObject historyModel: null

    /*experimental.certificateVerificationDialog: CertificateVerificationDialog {}
    experimental.authenticationDialog: AuthenticationDialog {}
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {}
    experimental.alertDialog: AlertDialog {}
    experimental.confirmDialog: ConfirmDialog {}
    experimental.promptDialog: PromptDialog {}*/

    /*selectionActions: ActionList {
        Actions.Copy {
            onTriggered: selection.copy()
        }
    }*/

    /*experimental.onPermissionRequested: {
        if (permission.type === PermissionRequest.Geolocation) {
            if (webview.toolbar) {
                webview.toolbar.close()
            }
            var text = i18n.tr("This page wants to know your device’s location.")
            PopupUtils.open(Qt.resolvedUrl("PermissionRequest.qml"),
                            webview.currentWebview,
                            {"permission": permission, "text": text})
        }
        // TODO: handle other types of permission requests
        // TODO: we might want to store the answer to avoid requesting
        //       the permission everytime the user visits this site.
    }*/

    QtObject {
        id: internal
        property int lastLoadRequestStatus: -1
    }
    readonly property bool lastLoadSucceeded: internal.lastLoadRequestStatus === LoadEvent.TypeSucceeded
    readonly property bool lastLoadStopped: internal.lastLoadRequestStatus === LoadEvent.TypeStopped
    readonly property bool lastLoadFailed: internal.lastLoadRequestStatus === LoadEvent.TypeFailed
    onLoadingChanged: {
        if (loadEvent.url.toString() === "data:text/html,chromewebdata") {
            return
        }
        internal.lastLoadRequestStatus = loadEvent.type
        if (historyModel && (loadEvent.type === LoadEvent.TypeSucceeded)) {
            historyModel.add(webview.url, webview.title, "")//webview.icon)
        }
    }
}
