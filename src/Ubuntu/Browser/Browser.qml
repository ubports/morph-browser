/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1

FocusScope {
    id: browser

    property bool chromeless: false
    property alias url: webview.url
    // title is a bound property instead of an alias because of QTBUG-29141
    property string title: webview.title

    focus: true

    WebView {
        id: webview

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: osk.top
        }

        focus: true
        interactive: !selection.visible

        property real scale: experimental.test.contentsScale * experimental.test.devicePixelRatio

        // iOS 5.0’s iPhone user agent
        experimental.userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"

        experimental.preferences.navigatorQtObjectEnabled: true
        experimental.userScripts: [Qt.resolvedUrl("selection.js")]
        experimental.onMessageReceived: {
            var data = null
            try {
                data = JSON.parse(message.data)
            } catch (error) {
                console.debug('DEBUG:', message.data)
                return
            }
            if ('event' in data) {
                if ((data.event === 'longpress') || (data.event === 'selectionadjusted')) {
                    selection.clearData()
                    selection.createData()
                    if ('html' in data) {
                        selection.mimedata.html = data.html
                    }
                    if ('text' in data) {
                        selection.mimedata.text = data.text
                    }
                    if ('images' in data) {
                        // TODO: download and cache the images locally
                        // (grab them from the webview’s cache, if possible),
                        // and forward local URLs.
                        selection.mimedata.urls = data.images
                    }
                    selection.show(data.left * scale, data.top * scale,
                                   data.width * scale, data.height * scale)
                }
            }
        }

        onUrlChanged: {
            if (!browser.chromeless) {
                chromeLoader.item.url = url
            }
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                revealingBar.hide()
            }
        }

        onLoadingChanged: {
            error.visible = (loadRequest.status === WebView.LoadFailedStatus)
        }
    }

    Selection {
        id: selection

        anchors.fill: webview
        visible: false

        property Item __popover: null
        property var mimedata: null

        function createData() {
            if (mimedata === null) {
                mimedata = Clipboard.newData()
            }
        }

        function clearData() {
            if (mimedata !== null) {
                delete mimedata
                mimedata = null
            }
        }

        function __showPopover() {
            __popover = PopupUtils.open(Qt.resolvedUrl("SelectionPopover.qml"), selection.rect)
            __popover.selection = selection
        }

        function show(x, y, width, height) {
            rect.x = x
            rect.y = y
            rect.width = width
            rect.height = height
            visible = true
            __showPopover()
        }

        function dismiss() {
            visible = false
            if (__popover != null) {
                PopupUtils.close(__popover)
                __popover = null
            }
        }

        onResized: {
            var message = new Object
            message.query = 'adjustselection'
            var rect = selection.rect
            var scale = webview.scale
            message.left = rect.x / scale
            message.right = (rect.x + rect.width) / scale
            message.top = rect.y / scale
            message.bottom = (rect.y + rect.height) / scale
            webview.experimental.postMessage(JSON.stringify(message))
            __showPopover()
        }

        function share() {
            console.log("TODO: share selection")
        }

        function save() {
            console.log("TODO: save selection")
        }

        function copy() {
            Clipboard.push(mimedata)
            clearData()
        }
    }

    ErrorSheet {
        id: error
        anchors.fill: webview
        visible: false
        url: webview.url
        onRefreshClicked: webview.reload()
    }

    Scrollbar {
        flickableItem: webview
        align: Qt.AlignTrailing
    }

    Scrollbar {
        flickableItem: webview
        align: Qt.AlignBottom
    }

    RevealingBar {
        id: revealingBar
        enabled: !browser.chromeless
        contents: chromeLoader.item
        anchors.bottom: osk.top
        locked: osk.height > 0
    }

    Loader {
        id: chromeLoader

        active: !browser.chromeless
        source: "Chrome.qml"

        anchors.left: parent.left
        anchors.right: parent.right

        height: units.gu(8)

        Binding {
            target: chromeLoader.item
            property: "canGoBack"
            value: webview.canGoBack
        }

        Binding {
            target: chromeLoader.item
            property: "canGoForward"
            value: webview.canGoForward
        }

        Connections {
            target: chromeLoader.item
            onGoBackClicked: webview.goBack()
            onGoForwardClicked: webview.goForward()
            onUrlValidated: {
                browser.url = url
                webview.forceActiveFocus()
            }
        }
    }

    KeyboardRectangle {
        id: osk
    }
}
