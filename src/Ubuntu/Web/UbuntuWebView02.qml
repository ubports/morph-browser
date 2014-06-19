/*
 * Copyright 2013-2014 Canonical Ltd.
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
                internal.dismissCurrentContextualMenu()
                internal.dismissCurrentSelection()
                internal.fillContextualData(msg.args)
                if (contextualActions != null) {
                    for (var i = 0; i < contextualActions.actions.length; ++i) {
                        if (contextualActions.actions[i].enabled) {
                            contextualRectangle.position(msg.args)
                            internal.currentContextualMenu = PopupUtils.open(contextualPopover, contextualRectangle)
                            break
                        }
                    }
                }
            }
        },
        Oxide.ScriptMessageHandler {
            msgId: "selection"
            contexts: ["oxide://selection/"]
            callback: function(msg, frame) {
                internal.dismissCurrentSelection()
                internal.dismissCurrentContextualMenu()
                if (selectionActions != null) {
                    for (var i = 0; i < selectionActions.actions.length; ++i) {
                        if (selectionActions.actions[i].enabled) {
                            var mimedata = internal.buildMimedata(msg.args)
                            var bounds = internal.computeBounds(msg.args)
                            internal.currentSelection = selection.createObject(_webview, {mimedata: mimedata, bounds: bounds})
                            internal.currentSelection.showActions()
                            break
                        }
                    }
                }
            }
        },
        Oxide.ScriptMessageHandler {
            msgId: "scroll"
            contexts: ["oxide://selection/"]
            callback: function(msg, frame) {
                internal.dismissCurrentContextualMenu()
                internal.dismissCurrentSelection()
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

    property ActionList selectionActions
    onSelectionActionsChanged: {
        for (var i in selectionActions.actions) {
            selectionActions.actions[i].onTriggered.connect(function () {
                internal.dismissCurrentSelection()
            })
        }
    }
    Component {
        id: selection
        Selection {
            anchors.fill: parent
            property var mimedata: null
            property rect bounds
            onBoundsChanged: {
                rect.x = bounds.x
                rect.y = bounds.y
                rect.width = bounds.width
                rect.height = bounds.height
            }
            property Item actions: null
            Component {
                id: selectionPopover
                ActionSelectionPopover {
                    autoClose: false
                    actions: selectionActions
                }
            }
            function showActions() {
                if (actions != null) {
                    actions.destroy()
                }
                actions = PopupUtils.open(selectionPopover, rect)
            }
            onResizingChanged: {
                if (resizing) {
                    if (actions != null) {
                        actions.destroy()
                    }
                }
            }
            onResized: {
                var args = {x: rect.x, y: rect.y, width: rect.width, height: rect.height}
                var msg = _webview.rootFrame.sendMessage("oxide://selection/", "adjustselection", args)
                msg.onreply = function(response) {
                    internal.currentSelection.mimedata = internal.buildMimedata(response)
                    // Ensure that the bounds are updated
                    internal.currentSelection.bounds = Qt.rect(0, 0, 0, 0)
                    internal.currentSelection.bounds = internal.computeBounds(response)
                    internal.currentSelection.showActions()
                }
                msg.onerror = function(error) {
                    internal.dismissCurrentSelection()
                }
            }
            onDismissed: internal.dismissCurrentSelection()
        }
    }
    function copy() {
        if (internal.currentSelection != null) {
            Clipboard.push(internal.currentSelection.mimedata)
        } else {
            console.warn("No current selection")
        }
    }

    QtObject {
        id: internal
        property int lastLoadRequestStatus: -1
        property Item currentContextualMenu: null
        property Item currentSelection: null

        function fillContextualData(data) {
            contextualData.clear()
            if ('img' in data) {
                contextualData.img = data.img
            }
            if ('href' in data) {
                contextualData.href = data.href
                contextualData.title = data.title
            }
        }

        function buildMimedata(data) {
            var mimedata = Clipboard.newData()
            if ('html' in data) {
                mimedata.html = data.html
            }
            // FIXME: push the text and image data in the order
            // they appear in the selected block.
            if ('text' in data) {
                mimedata.text = data.text
            }
            if ('images' in data) {
                // TODO: download and cache the images locally
                // (grab them from the webview’s cache, if possible),
                // and forward local URLs.
                mimedata.urls = data.images
            }
            return mimedata
        }

        function computeBounds(data) {
            return Qt.rect(data.left * data.scaleX, data.top * data.scaleY,
                           data.width * data.scaleX, data.height * data.scaleY)
        }

        function dismissCurrentContextualMenu() {
            if (currentContextualMenu != null) {
                PopupUtils.close(currentContextualMenu)
            }
        }

        function dismissCurrentSelection() {
            if (currentSelection != null) {
                currentSelection.destroy()
            }
        }
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
        internal.dismissCurrentContextualMenu()
        internal.dismissCurrentSelection()
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
