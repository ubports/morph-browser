/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Web 0.2
import com.canonical.Oxide 1.4 as Oxide
import webbrowserapp.private 0.1
import "."

FocusScope {
    id: tab

    property string uniqueId: this.toString() + "-" + Date.now()
    property url initialUrl
    property string initialTitle
    property url initialIcon
    property string restoreState
    property int restoreType
    property var request
    property Component webviewComponent
    readonly property var webview: webviewContainer.webview
    readonly property url url: webview ? webview.url : initialUrl
    readonly property string title: webview ? webview.title : initialTitle
    readonly property url icon: webview ? webview.icon : initialIcon
    property url preview
    property bool current: false
    property bool incognito
    property LimitProxyModel topSites
    signal cachedPreviewUpdated(url url)

    Connections {
        target: PreviewManager
        onPreviewSaved: {
            if (pageUrl !== url) return
            if (preview == previewUrl) {
                // Ensure that the preview URL actually changes,
                // for the image to be reloaded
                preview = ""
            }
            preview = previewUrl
        }
    }

    FocusScope {
        id: webviewContainer
        anchors.fill: parent
        focus: true
        readonly property var webview: (children.length == 1) ? children[0] : null
    }

    function load() {
        if (!webview) {
            var properties = {'tab': tab, 'incognito': incognito}
            if (restoreState) {
                properties['restoreState'] = restoreState
                properties['restoreType'] = restoreType
            } else {
                properties['url'] = initialUrl
            }
            webviewComponent.incubateObject(webviewContainer, properties)
        }
    }

    function unload() {
        if (webview) {
            initialUrl = webview.url
            initialTitle = webview.title
            initialIcon = webview.icon
            restoreState = webview.currentState
            restoreType = Oxide.WebView.RestoreCurrentSession
            webview.destroy()
        }
    }

    function close() {
        unload()
        PreviewManager.checkDelete(url)
        destroy()
    }

    QtObject {
        id: internal
        property bool hiding: false
    }

    // When current is set to false, delay hiding the tab contents to give it
    // an opportunity to grab an up-to-date capture. This works well if and
    // only if embedders do not set the 'visible' property directly or
    // indirectly on instances of a BrowserTab.
    onCurrentChanged: {
        if (current) {
            internal.hiding = false
            visible = true
        } else if (visible && !internal.hiding) {
            if (!webview || webview.incognito) {
                // XXX: Do not grab a capture in incognito mode, as we don’t
                // want to write anything to disk. This means tab previews won’t
                // be available. In the future, we’ll want to grab a capture
                // and cache it in memory, but QQuickItem::grabToImage doesn’t
                // allow that.
                visible = false
                return
            }

            if (url.toString().length === 0) {
                visible = false;
                return;
            }

            internal.hiding = true
            webview.grabToImage(function(result) {
                if (!internal.hiding) {
                    return
                }
                internal.hiding = false
                visible = false

                PreviewManager.saveToDisk(result, url)
            })
        }
    }

    Component.onCompleted: {
        if (request) {
            // Instantiating the webview cannot be delayed because the request
            // object is destroyed after exiting the newViewRequested signal handler.
            webviewComponent.incubateObject(webviewContainer, {"tab": tab, "request": request, 'incognito': incognito})
        }
    }
}
