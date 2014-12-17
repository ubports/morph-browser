/*
 * Copyright 2014 Canonical Ltd.
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
import webbrowserapp.private 0.1

FocusScope {
    property string uniqueId: this.toString() + "-" + Date.now()
    property url initialUrl
    property string initialTitle
    property var request
    property Component webviewComponent
    readonly property var webview: webviewContainer.webview
    readonly property url url: webview ? webview.url : initialUrl
    readonly property string title: webview ? webview.title : initialTitle
    readonly property url icon: webview ? webview.icon : ""
    property url preview

    FocusScope {
        id: webviewContainer
        anchors.fill: parent
        focus: true
        readonly property var webview: (children.length == 1) ? children[0] : null
    }

    function load() {
        if (!webview) {
            webviewComponent.incubateObject(webviewContainer, {"url": initialUrl})
        }
    }

    function unload() {
        if (webview) {
            initialUrl = webview.url
            initialTitle = webview.title
            webview.destroy()
        }
    }

    function close() {
        unload()
        if (preview) {
            FileOperations.remove(preview)
        }
        destroy()
    }

    property var captureTaker
    Component {
        id: captureComponent
        ItemCapture {
            quality: 50
            onCaptureFinished: {
                if ((request == uniqueId) && capture.toString()) {
                    if (preview == capture) {
                        // Ensure that the preview URL actually changes,
                        // for the image to be reloaded
                        preview = ""
                    }
                    preview = capture
                }
                if (!webview.visible) {
                    captureTaker.destroy()
                }
            }
        }
    }
    function createCaptureTakerIfNeeded() {
        if (!captureTaker) {
            captureTaker = captureComponent.createObject(webview)
        }
    }
    onWebviewChanged: {
        if (webview) {
            createCaptureTakerIfNeeded()
        }
    }

    Connections {
        target: webview
        onVisibleChanged: {
            if (webview.visible) {
                createCaptureTakerIfNeeded()
            } else {
                captureTaker.requestCapture(uniqueId)
            }
        }
    }

    Component.onCompleted: {
        if (request) {
            // Instantiating the webview cannot be delayed because the request
            // object is destroyed after exiting the newViewRequested signal handler.
            webviewComponent.incubateObject(webviewContainer, {"request": request})
        }
    }
}
