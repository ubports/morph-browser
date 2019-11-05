/*
 * Copyright 2016 Canonical Ltd.
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
import Morph.Web 0.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import "../actions" as Actions
import ".."

WebViewImpl {
    id: webappWebview

    property bool wide: false

    signal openUrlExternallyRequested(string url)

    Loader {
        id: contentHandlerLoader
        source: "../ContentHandler.qml"
        asynchronous: true
    }

    QtObject {
        id: internal

        function instantiateShareComponent() {
            var component = Qt.createComponent("../Share.qml")
            if (component.status === Component.Ready) {
                var share = component.createObject(webappWebview)
                share.onDone.connect(share.destroy)
                return share
            }
            return null
        }

        function shareLink(url, title) {
            var share = instantiateShareComponent()
            if (share) share.shareLink(url, title)
        }

        function shareText(text) {
            var share = instantiateShareComponent()
            if (share) share.shareText(text)
        }
    }

    Loader {
        id: filePickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }
}
