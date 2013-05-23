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
import QtQuick.Window 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1

WebView {
    id: _webview

    QtObject {
        // clumsy way of defining an enum in QML
        id: formFactor
        readonly property int desktop: 0
        readonly property int phone: 1
        readonly property int tablet: 2
    }
    // FIXME: this is a quick hack that will become increasingly unreliable
    // as we support more devices, so we need a better solution for this
    // FIXME: only handling phone and tablet for now
    property int formFactor: (Screen.width >= units.gu(60)) ? formFactor.tablet : formFactor.phone

    interactive: !selection.visible
    maximumFlickVelocity: height * 5

    property real scale: experimental.test.contentsScale * experimental.test.devicePixelRatio

    experimental.userAgent: {
        // FIXME: using iOS 5.0’s iPhone/iPad user-agent strings
        // (source: http://stackoverflow.com/questions/7825873/what-is-the-ios-5-0-user-agent-string),
        // this should be changed to a more neutral user-agent in the
        // future as we don’t want websites to recommend installing
        // their iPhone/iPad apps.
        if (formFactor === formFactor.phone) {
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
        } else if (formFactor === formFactor.tablet) {
            return "Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
        } else {
            return ""
        }
    }

    experimental.preferences.navigatorQtObjectEnabled: true
    experimental.userScripts: [Qt.resolvedUrl("hyperlinks.js"),
                               Qt.resolvedUrl("selection.js")]
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
                // FIXME: push the text and image data in the order
                // they appear in the selected block.
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

    experimental.itemSelector: ItemSelector {}

    Selection {
        id: selection

        anchors.fill: parent
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

        onVisibleChanged: {
            if (!visible && (__popover != null)) {
                PopupUtils.close(__popover)
                __popover = null
            }
        }

        onResized: {
            var message = new Object
            message.query = 'adjustselection'
            var rect = selection.rect
            var scale = _webview.scale
            message.left = rect.x / scale
            message.right = (rect.x + rect.width) / scale
            message.top = rect.y / scale
            message.bottom = (rect.y + rect.height) / scale
            _webview.experimental.postMessage(JSON.stringify(message))
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

    Scrollbar {
        parent: _webview.parent
        flickableItem: _webview
        align: Qt.AlignTrailing
    }

    Scrollbar {
        parent: _webview.parent
        flickableItem: _webview
        align: Qt.AlignBottom
    }
}
