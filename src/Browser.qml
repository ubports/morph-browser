/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of kalossi-browser.
 *
 * kalossi-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * kalossi-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtWebKit 3.0
//import QtWebKit.experimental 1.0
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
