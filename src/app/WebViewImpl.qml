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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Web 0.2
import webbrowsercommon.private 0.1
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
            if (request.cookies.length > 0) {
                headers["Cookie"] = request.cookies.join(";")
            }
            if (request.referrer) {
                headers["Referer"] = request.referrer
            }
            headers["User-Agent"] = webview.context.userAgent
            // Work around https://launchpad.net/bugs/1487090 by guessing the mime type
            // from the suggested filename or URL if oxide hasn’t provided one.
            var mimeType = request.mimeType
            if (!mimeType) {
                mimeType = MimeDatabase.filenameToMimeType(request.suggestedFilename)
            }
            if (!mimeType) {
                var scheme = request.url.toString().split('://').shift().toLowerCase()
                var filename = request.url.toString().split('/').pop()
                if ((scheme == "file") || (filename.indexOf('.') > -1)) {
                    mimeType = MimeDatabase.filenameToMimeType(filename)
                }
            }
            downloadLoader.item.downloadMimeType(request.url, mimeType, headers, request.suggestedFilename)
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
        // TODO: Use the ubuntu download manager on desktop as well
        //  (https://launchpad.net/bugs/1477310). This will require to have
        //  ubuntu-download-manager in main (https://launchpad.net/bugs/1488425).
        source: formFactor == "desktop" ? "" : "Downloader.qml"
        asynchronous: true
    }

    function requestGeolocationPermission(request) {
        PopupUtils.open(Qt.resolvedUrl("GeolocationPermissionRequest.qml"),
                        webview.currentWebview, {"request": request})
        // TODO: we might want to store the answer to avoid requesting
        //       the permission everytime the user visits this site.
    }
}
