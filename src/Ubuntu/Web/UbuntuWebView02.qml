/*
 * Copyright 2013-2015 Canonical Ltd.
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
import com.canonical.Oxide 1.8 as Oxide
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
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

    context: SharedWebContext.sharedContext

    messageHandlers: [
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

    popupMenu: ItemSelector02 {
        automaticOrientation: false
    }

    Item {
        id: contextualRectangle
        visible: false
        readonly property real locationBarOffset: _webview.locationBarController.height + _webview.locationBarController.offset
        // XXX: does this take the scale factor into account?
        x: internal.contextModel ? internal.contextModel.position.x : 0
        y: internal.contextModel ? internal.contextModel.position.y + locationBarOffset : 0
    }

    property QtObject contextualData: QtObject {
        // TODO: mark deprecated
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
    contextMenu: ActionSelectionPopover {
        actions: contextualActions
        caller: contextualRectangle
        Component.onCompleted: {
            internal.dismissCurrentContextualMenu()
            internal.dismissCurrentSelection()
            internal.contextModel = model
            var empty = true
            if (actions) {
                for (var i in actions.actions) {
                    if (actions.actions[i].enabled) {
                        empty = false
                        break
                    }
                }
            }
            if (empty) {
                if (internal.hasSelectionActions()) {
                    internal.createSelection(model.position)
                }
                internal.dismissCurrentContextualMenu()
            } else {
                contextualData.clear()
                contextualData.href = model.linkUrl
                contextualData.title = model.linkText
                if ((model.mediaType == Oxide.WebView.MediaTypeImage) && model.hasImageContents) {
                    contextualData.img = model.srcUrl
                }
                show()
            }
        }
        onVisibleChanged: {
            if (!visible) {
                internal.dismissCurrentContextualMenu()
            }
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
                    objectName: "selectionActions"
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
                var locationBarOffset = _webview.locationBarController.height + _webview.locationBarController.offset
                var args = {x: rect.x, y: rect.y - locationBarOffset,
                            width: rect.width, height: rect.height}
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
    function createSelection(position) {
        internal.createSelection(position)
    }

    QtObject {
        id: internal
        property int lastLoadRequestStatus: -1
        property Item currentSelection: null
        property QtObject contextModel: null

        function hasSelectionActions() {
            if (selectionActions) {
                for (var i in selectionActions.actions) {
                    if (selectionActions.actions[i].enabled) {
                        return true
                    }
                }
            }
            return false
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
            var locationBarOffset = _webview.locationBarController.height + _webview.locationBarController.offset
            var scaleX = data.outerWidth / data.innerWidth * data.dpr
            var scaleY = data.outerHeight / (data.innerHeight + locationBarOffset) * data.dpr
            return Qt.rect(data.left * scaleX, data.top * scaleY + locationBarOffset,
                           data.width * scaleX, data.height * scaleY)
        }

        function createSelection(position) {
            var msg = _webview.rootFrame.sendMessage("oxide://selection/", "createselection",
                                                     {x: position.x, y: position.y})
            msg.onreply = function(response) {
                var mimedata = internal.buildMimedata(response)
                var bounds = internal.computeBounds(response)
                internal.currentSelection = selection.createObject(_webview, {mimedata: mimedata, bounds: bounds})
                internal.currentSelection.showActions()
            }
        }

        function dismissCurrentContextualMenu() {
            if (contextModel) {
                contextModel.close()
            }
        }

        function dismissCurrentSelection() {
            if (currentSelection != null) {
                // For some reason a 0 delay fails to destroy the selection
                // when it was requested upon a screen orientation change…
                currentSelection.destroy(1)
            }
        }

        // Automatically clear the contextual data when the context model is destroyed
        readonly property var contextualDataCleaner: contextModel ? 0 : _webview.contextualData.clear()
    }

    readonly property bool lastLoadSucceeded: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeSucceeded
    readonly property bool lastLoadStopped: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeStopped
    readonly property bool lastLoadFailed: internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeFailed
    onLoadEvent: {
        if (!event.isError) {
            internal.lastLoadRequestStatus = event.type
        }
        internal.dismissCurrentContextualMenu()
        internal.dismissCurrentSelection()
    }

    readonly property int screenOrientation: Screen.orientation
    onScreenOrientationChanged: {
        internal.dismissCurrentContextualMenu()
        internal.dismissCurrentSelection()
    }

    onJavaScriptConsoleMessage: {
        if (_webview.incognito) {
            return
        }

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
