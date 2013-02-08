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

        property real scale: experimental.test.contentsScale * experimental.test.devicePixelRatio

        // iOS 5.0’s iPhone user agent
        experimental.userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"

        experimental.preferences.navigatorQtObjectEnabled: true
        experimental.onMessageReceived: {
            var data = JSON.parse(message.data)
            if ('event' in data) {
                var event = data.event
                delete data.event
                if (event === 'longpress') {
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
            if (loadRequest.status === WebView.LoadSucceededStatus) {
                var query = (function() {
                    var doc = document.documentElement;
                    function getImgFullUri(uri) {
                        if ((uri.slice(0, 7) === 'http://') ||
                            (uri.slice(0, 8) === 'https://') ||
                            (uri.slice(0, 7) === 'file://')) {
                            return uri;
                        } else if (uri.slice(0, 1) === '/') {
                            var docuri = document.documentURI;
                            var firstcolon = docuri.indexOf('://');
                            var protocol = 'http://';
                            if (firstcolon !== -1) {
                                protocol = docuri.slice(0, firstcolon + 3);
                            }
                            return protocol + document.domain + uri;
                        } else {
                            var base = document.baseURI;
                            var lastslash = base.lastIndexOf('/');
                            if (lastslash === -1) {
                                return base + '/' + uri;
                            } else {
                                return base.slice(0, lastslash + 1) + uri;
                            }
                        }
                    }
                    function longPressDetected(x, y) {
                        var element = document.elementFromPoint(x, y);
                        var data = element.getBoundingClientRect();
                        data['event'] = 'longpress';
                        data['html'] = element.outerHTML;
                        data['text'] = element.textContent;
                        var images = [];
                        if (element.tagName.toLowerCase() === 'img') {
                            images.push(getImgFullUri(element.getAttribute('src')));
                        } else {
                            var imgs = element.getElementsByTagName('img');
                            for (var i = 0; i < imgs.length; i++) {
                                images.push(getImgFullUri(img.getAttribute('src')));
                            }
                        }
                        if (images.length > 0) {
                            data['images'] = images;
                        }
                        navigator.qt.postMessage(JSON.stringify(data));
                    }
                    doc.addEventListener('touchstart', function(event) {
                        this.currentTouch = event.touches[0];
                        this.longpressObserver = setTimeout(longPressDetected, 800, this.currentTouch.clientX, this.currentTouch.clientY);
                    });
                    doc.addEventListener('touchend', function(event) {
                        clearTimeout(this.longpressObserver);
                        delete this.longpressObserver;
                        delete this.currentTouch;
                    });
                    doc.addEventListener('touchmove', function(event) {
                          var touch = event.changedTouches[0];
                          var distance = Math.sqrt(Math.pow(touch.clientX - this.currentTouch.clientX, 2) + Math.pow(touch.clientY - this.currentTouch.clientY, 2));
                          if (distance > 3) {
                              clearTimeout(this.longpressObserver);
                              delete this.longpressObserver;
                              delete this.currentTouch;
                          }
                    });
                })
                webview.experimental.evaluateJavaScript('(' + query.toString() + ')()')
            }
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
            // TODO: talk to the DOM to compute the block element below the
            // selection, resize the rectangle to fit it, and update the
            // contents of the corresponding MIME data.
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
