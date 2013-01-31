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
    // title is a bound property instead of an alias because of QTBUG-29141
    property string title: webview.title

    WebView {
        id: webview

        anchors.fill: parent

        // iOS 5.0’s iPhone user agent
        experimental.userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"

        onUrlChanged: chrome.url = url
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
        anchors.bottom: osk.top
        height: units.gu(8)

        canGoBack: webview.canGoBack
        onGoBackClicked: webview.goBack()
        canGoForward: webview.canGoForward
        onGoForwardClicked: webview.goForward()
        onReloadClicked: webview.reload()
        onUrlValidated: {
            browser.url = url
            webview.forceActiveFocus()
        }

        loading: webview.loading
    }

    KeyboardRectangle {
        id: osk
    }
}
