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

Item {
    id: browser

    property bool chromeless: false
    property alias url: webview.url

    WebView {
        id: webview

        anchors.fill: parent

        onUrlChanged: chrome.url = url
    }

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: chrome.top
        anchors.left: parent.left
        anchors.right: parent.right

        onPressAndHold: {
            selection.visible = false
            var scale = webview.experimental.test.contentsScale
            var x = parseInt(mouse.x / scale)
            var y = parseInt(mouse.y / scale)
            var query =
                    "(function() {" +
                    "    var element = document.elementFromPoint(" + x + "," + y + ");" +
                    "    var rect = element.getBoundingClientRect();" +
                    "    return [rect.left, rect.top, rect.right, rect.bottom, element.outerHTML];" +
                    "})()"
            webview.experimental.evaluateJavaScript(query,
                function(r) {
                    console.log("selected element:", r[4])
                    var scale = webview.experimental.test.contentsScale
                    selection.x = r[0] * scale
                    selection.y = r[1] * scale
                    selection.width = (r[2] - r[0]) * scale
                    selection.height = (r[3] - r[1]) * scale
                    selection.visible = true
                })
        }
    }

    Rectangle {
        id: selection
        color: "#F07846"
        opacity: 0.4
        visible: false
    }

    Scrollbar {
        flickableItem: webview
        align: Qt.AlignTrailing
    }

    Scrollbar {
        flickableItem: webview
        align: Qt.AlignBottom
    }

    Chrome {
        id: chrome

        visible: !browser.chromeless
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: units.gu(8)

        canGoBack: webview.canGoBack
        onGoBackClicked: webview.goBack()
        canGoForward: webview.canGoForward
        onGoForwardClicked: webview.goForward()
        onReloadClicked: webview.reload()
        onUrlValidated: browser.url = url

        loading: webview.loading
    }
}
