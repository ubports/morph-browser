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
import com.canonical.Oxide 1.0 as Oxide
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1
import "." // QTBUG-34418

Oxide.WebView {
    id: _webview

    /**
     * Client overridable function called before the default treatment of a
     *  valid navigation request. This function can stop the navigation request
     *  if it sets the 'action' field of the request to IgnoreRequest.
     *
     */
    function navigationRequestedDelegate(request) { }

    /**
     * This function can be overridden by client applications that embed an
     * UbuntuWebView to provide a static overridden UA string.
     * If not overridden, the default UA string and the default override
     * mechanism will be used.
     *
     * Note: as the UA string is a property of the shared context,
     * an application that embeds several UbuntuWebViews that define different
     * custom UA strings will result in the last view instantiated setting the
     * UA for all the views.
     */
    function getUAString() {
        return undefined
    }

    context: SharedWebContext.sharedContext
    Component.onCompleted: {
        var customUA = getUAString()
        if (customUA !== undefined) {
            SharedWebContext.customUA = customUA
        }
    }

    messageHandlers: [
        Oxide.ScriptMessageHandler {
            msgId: "contextmenu"
            contexts: ["oxide://selection/"]
            callback: function(msg, frame) {
                if (('img' in msg.args) || ('href' in msg.args)) {
                    if (internal.currentContextualMenu != null) {
                        PopupUtils.close(internal.currentContextualMenu)
                    }
                    contextualData.clear()
                    if ('img' in msg.args) {
                        contextualData.img = msg.args.img
                    }
                    if ('href' in msg.args) {
                        contextualData.href = msg.args.href
                        contextualData.title = msg.args.title
                    }
                    contextualRectangle.position(msg.args)
                    internal.currentContextualMenu = PopupUtils.open(contextualPopover, contextualRectangle)
                } else if (internal.currentContextualMenu != null) {
                    PopupUtils.close(internal.currentContextualMenu)
                }
            }
        },
        Oxide.ScriptMessageHandler {
            msgId: "scroll"
            contexts: ["oxide://selection/"]
            callback: function(msg, frame) {
                if (internal.currentContextualMenu != null) {
                    PopupUtils.close(internal.currentContextualMenu)
                }
            }
        }
    ]

    onNavigationRequested: {
        request.action = Oxide.NavigationRequest.ActionAccept;
        navigationRequestedDelegate(request);
    }

    preferences.passwordEchoEnabled: formFactor === "mobile"

    popupMenu: ItemSelector02 {}

    Item {
        id: contextualRectangle

        visible: false

        function position(data) {
            x = data.left * data.scaleX
            y = data.top * data.scaleY
            width = data.width * data.scaleX
            height = data.height * data.scaleY
        }
    }
    property QtObject contextualData: QtObject {
        property url href
        property string title
        property url img

        function clear() {
            href = ''
            title = ''
            img = ''
        }
    }

    property ActionList contextualActions
    Component {
        id: contextualPopover
        ActionSelectionPopover {
            actions: contextualActions
        }
    }

    QtObject {
        id: internal
        property int lastLoadRequestStatus: -1
        property Item currentContextualMenu: null
    }

    readonly property bool lastLoadSucceeded: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeSucceeded
    readonly property bool lastLoadStopped: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeStopped
    readonly property bool lastLoadFailed: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeFailed
    onLoadingChanged: {
        if (loadEvent.url.toString() !== "data:text/html,chromewebdata") {
            internal.lastLoadRequestStatus = loadEvent.type
        }
    }

    readonly property int screenOrientation: Screen.orientation
    onScreenOrientationChanged: {
        if (internal.currentContextualMenu != null) {
            PopupUtils.close(internal.currentContextualMenu)
        }
    }

    onJavaScriptConsoleMessage: {
        var msg = "[JS] (%1:%2) %3".arg(sourceId).arg(lineNumber).arg(message)
        if (level === Oxide.WebView.LogSeverityVerbose) {
            console.log(msg)
        } else if (level === Oxide.WebView.LogSeverityInfo) {
            console.info(msg)
        } else if (level === Oxide.WebView.LogSeverityWarning) {
            console.warn(msg)
        } else if ((level === Oxide.WebView.LogSeverityError) ||
                   (level === Oxide.WebView.LogSeverityErrorReport) ||
                   (level === Oxide.WebView.LogSeverityFatal)) {
            console.error(msg)
        }
    }
}
