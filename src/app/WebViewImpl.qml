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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Web 0.2
import "actions" as Actions

WebView {
    id: webview

    property var currentWebview: webview

    /*experimental.certificateVerificationDialog: CertificateVerificationDialog {}
    experimental.authenticationDialog: AuthenticationDialog {}
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {}*/
    alertDialog: AlertDialog {}
    confirmDialog: ConfirmDialog {}
    promptDialog: PromptDialog {}
    beforeUnloadDialog: BeforeUnloadDialog {}
    filePicker: filePickerLoader.item

    QtObject {
        id: internal

        readonly property var downloadMimeTypesBlacklist: [
            "application/x-shockwave-flash", // http://launchpad.net/bugs/1379806
        ]
    }

    onFullscreenRequested: webview.fullscreen = fullscreen

    onDownloadRequested: {
        if (!request.suggestedFilename && request.mimeType &&
            internal.downloadMimeTypesBlacklist.indexOf(request.mimeType) > -1) {
            return
        }

        if (downloadLoader.status == Loader.Ready) {
            var headers = { }
            if(request.cookies.length > 0) {
                headers["Cookie"] = request.cookies.join(";")
            }
            if(request.referrer) {
                headers["Referer"] = request.referrer
            }
            headers["User-Agent"] = webview.context.userAgent
            downloadLoader.item.downloadMimeType(request.url, request.mimeType, headers, request.suggestedFilename)
        } else {
            // Desktop form factor case
            Qt.openUrlExternally(request.url)
        }
    }

    Loader {
        id: filePickerLoader
        source: formFactor == "desktop" ? "FilePickerDialog.qml" : "ContentPickerDialog.qml"
        asynchronous: true
    }

    Loader {
        id: downloadLoader
        source: formFactor == "desktop" ? "" : "Downloader.qml"
        asynchronous: true
    }

    selectionActions: ActionList {
        Actions.Copy {
            onTriggered: copy()
        }
    }

    function requestGeolocationPermission(request) {
        PopupUtils.open(Qt.resolvedUrl("GeolocationPermissionRequest.qml"),
                        webview.currentWebview, {"request": request})
        // TODO: we might want to store the answer to avoid requesting
        //       the permission everytime the user visits this site.
    }
}
