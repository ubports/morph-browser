/*
 * Copyright 2014-2017 Canonical Ltd.
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
import QtQuick.Window 2.2
import QtWebEngine 1.5
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1
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
    readonly property url localIcon: faviconFetcher.localUrl
    property url preview
    property bool current: false
    readonly property real lastCurrent: internal.lastCurrent
    property bool incognito
    readonly property bool empty: !url.toString() && !initialUrl.toString() && !restoreState && !request
    visible: false

    // Used as a workaround for https://launchpad.net/bugs/1502675 :
    // invoke this on a tab shortly before it is set current.
    signal aboutToShow()

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

    FaviconFetcher {
        id: faviconFetcher
        shouldCache: !tab.incognito
        url: tab.icon
    }

    FocusScope {
        id: webviewContainer
        anchors.fill: parent
        focus: true
        property var webview: null
    }

    function load() {
        if (!webview && !internal.incubator) {
            var properties = {'tab': tab, 'incognito': incognito}
            if (restoreState) {
                properties['restoreState'] = restoreState
                properties['restoreType'] = restoreType
            } else {
                properties['url'] = initialUrl
            }
            var incubator = webviewComponent.incubateObject(webviewContainer, properties)
            if (incubator === null) {
                console.warn("Webview incubator failed to initialize")
                return
            }
            if (incubator.status === Component.Ready) {
                webviewContainer.webview = incubator.object
                return
            }
            internal.incubator = incubator
            incubator.onStatusChanged = function(status) {
                if (status === Component.Ready) {
                    webviewContainer.webview = incubator.object
                } else if (status === Component.Error) {
                    console.warn("Webview failed to incubate")
                }
                internal.incubator = null
            }
        }
    }

    function loadExisting(existingTab) {
        if (!webview && !internal.incubator) {
            // Reparent the webview and any other vars
            existingTab.webview.parent = webviewContainer;
            existingTab.webview.tab = tab;

            // Set the webview into this window
            webviewContainer.webview = existingTab.webview;
        }
    }

    function unload() {
        if (webview) {
            initialUrl = webview.url
            initialTitle = webview.title
            initialIcon = webview.icon
            webview.destroy()
            gc()
        }
    }

    function reload() {
        if (webview) {
            webview.reload()
        } else {
            load()
        }
    }

    function close(reparentDestroy) {
        var _url = url
        unload()
        if (_url.toString()) PreviewManager.checkDelete(_url)

        if (reparentDestroy || reparentDestroy === undefined) {
            // Destroys context and object
            Reparenter.destroyContextAndObject(tab);
        } else {
            destroy();
        }
    }

    QtObject {
        id: internal
        property bool hiding: false
        property var incubator: null
        property real lastCurrent: 0
    }

    // When current is set to false, delay hiding the tab contents to give it
    // an opportunity to grab an up-to-date capture. This works well if and
    // only if embedders do not set the 'visible' property directly or
    // indirectly on instances of a BrowserTab.
    onCurrentChanged: {
        internal.lastCurrent = Date.now()
        if (current) {
            internal.hiding = false
            z = 1
            opacity = 1
            visible = true
        } else if (visible && !internal.hiding) {
            z = -1
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
                visible = false
                return
            }

            if (Window.visibility == Window.Hidden) {
                visible = false
                return
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

    // Take a capture of the current page shortly after it has finished
    // loading to give rendering an opportunity to complete. There is
    // unfortunately no signal to notify us when rendering has completed.
    Timer {
        id: delayedCapture
        interval: 500
        onTriggered: {
            if (webview && current && visible && !internal.hiding) {
                webview.grabToImage(function(result) {
                    PreviewManager.saveToDisk(result, url)
                })
            }
        }
    }
    Connections {
        target: incognito ? null : webview
//        onLoadEvent: {
//            if ((event.type == Oxide.LoadEvent.TypeSucceeded) ||
//                (event.type == Oxide.LoadEvent.TypeFailed)) {
//                delayedCapture.restart()
//            }
//        }
    }

    onAboutToShow: {
        if (!current) {
            opacity = 0
            z = 1
            visible = true
            load()
        }
    }

    Component.onCompleted: {
        if (request) {
            // Instantiating the webview cannot be delayed because the request
            // object is destroyed after exiting the newViewRequested signal handler.
            var properties = {"tab": tab, "request": request, 'incognito': incognito}
            webviewContainer.webview = webviewComponent.createObject(webviewContainer, properties)
        }
    }
}
