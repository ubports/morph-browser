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
import Ubuntu.HUD 0.1 as HUD

FocusScope {
    id: browser

    property bool chromeless: false
    property alias url: webview.url
    // title is a bound property instead of an alias because of QTBUG-29141
    property string title: webview.title
    property string desktopFileHint: ""
    property string qtwebkitdpr: "1.0"
    property bool developerExtrasEnabled: false

    focus: true

    HUD.HUD {
        id: hud
        /*
         * As an unfortunate implementation detail the applicationIdentifier is
         * a bit special property of the HUD. It can only be set once; when it's set to
         * anything else than an empty string (which happens to be the default value)
         * the application gets registered to HUD with the given identifier which can not
         * be changed afterwards.
         *
         * Therefore we need to have the special "<not set>" value to indicate that there was
         * no hint set with the command line parameter and we should register as "webbrowser-app".
         *
         * We need to have a different applicationIdentifier for the browser because of webapps.
         *
         * Webapps with desktop files are executed like this:
         *
         *     $ webbrowser-app --chromeless http://m.amazon.com --desktop_file_hint=/usr/share/applications/amazon-webapp.desktop
         *
         * It is the Shell that adds the --desktop_file_hint command line argument.
         */
        applicationIdentifier: (browser.desktopFileHint == "<not set>") ? "webbrowser-app" : browser.desktopFileHint
        HUD.Context {
            toolbar.quitAction.onTriggered: Qt.quit()
            HUD.Action {
                label: "Goto"
                keywords: "Address;URL;www"
            }
            HUD.Action {
                label: "Back"
                keywords: "Older Page"
            }
            HUD.Action {
                label: "Forward"
                keywords: "Newer Page"
            }
            HUD.Action {
                label: "Reload"
                keywords: "Leave Page"
            }
            HUD.Action {
                label: "Bookmark"
                keywords: "Add This Page to Bookmarks"
            }
            HUD.Action {
                label: "New Tab"
                keywords: "Open a New Tab"
            }
        }
    }

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

        experimental.userAgent: {
            // FIXME: using iOS 5.0’s iPhone/iPad user-agent strings
            // (source: http://stackoverflow.com/questions/7825873/what-is-the-ios-5-0-user-agent-string),
            // this should be changed to a more neutral user-agent in the
            // future as we don’t want websites to recommend installing
            // their iPhone/iPad apps.
            if (browser.formFactor === formFactor.phone) {
                return "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
            } else if (browser.formFactor === formFactor.tablet) {
                return "Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
            }
        }

        experimental.devicePixelRatio: browser.qtwebkitdpr
        experimental.preferences.developerExtrasEnabled: browser.developerExtrasEnabled
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
            var scale = webview.scale
            message.left = rect.x / scale
            message.right = (rect.x + rect.width) / scale
            message.top = rect.y / scale
            message.bottom = (rect.y + rect.height) / scale
            webview.experimental.postMessage(JSON.stringify(message))
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

    ProgressBar {
        anchors {
            left: parent.left
            right: parent.right
            bottom: osk.top
        }
        height: units.gu(0.6)
        visible: value < 100

        minimumValue: 0
        maximumValue: 100
        indeterminate: value == 0
        value: webview.loadProgress
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
