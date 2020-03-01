/*
 * Copyright 2013-2017 Canonical Ltd.
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
import QtQuick.Window 2.2
import QtWebEngine 1.5
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "." // QTBUG-34418

WebEngineView {
    id: _webview

    property alias context: _webview.profile
    property var incognito: false

    property var locationBarController: QtObject {
        readonly property int modeAuto: 0
        readonly property int modeShown: 1
        readonly property int modeHidden: 2

        property bool animated: false
        property int mode: modeAuto
        function show(animate) {
            console.log('locationBarController.show() called')
            // TODO
        }
    }

    property var certificateError: null
    onCertificateError: certificateError = error
    function resetCertificateError() {
        certificateError = null
    }

    /**
    *   html select override
    *   set enableSelectOverride to true to make Morph.Web handle select
    *   note that as it uses javascript prompt,
    *   make sure that onJavaScriptDialogRequested signal handler don't overplay prompt dialog by checking the isASelectRequest(request)
    */

    property bool enableSelectOverride: false
    property var selectOverride: function(request) {
        var dialog = PopupUtils.open(Qt.resolvedUrl("MorphSelectOverrideDialog.qml"), this);
        dialog.options = request.defaultText;
        dialog.accept.connect(request.dialogAccept);
        dialog.reject.connect(request.dialogReject);
        //make sure to close dialogs after returning a value ( fix freeze with big dropdowns )
        dialog.accept.connect(function() { PopupUtils.close(dialog) })
        dialog.reject.connect(function() { PopupUtils.close(dialog) })
    }
    readonly property var isASelectRequest: function(request){
        return (request.type === JavaScriptDialogRequest.DialogTypePrompt && request.message==='XX-MORPH-SELECT-OVERRIDE-XX')
    }

    userScripts: WebEngineScript {
        runOnSubframes: true
        sourceUrl: enableSelectOverride && (screenDiagonal > 0 && screenDiagonal < 190)  ? Qt.resolvedUrl("select_overrides.js") : ""
        injectionPoint: WebEngineScript.DocumentCreation
        worldId: WebEngineScript.MainWorld
    }

    onJavaScriptDialogRequested: function(request) {

        if (enableSelectOverride && isASelectRequest(request)) {
            request.accepted = true
            selectOverride(request)
        }
    }


    /**
     * Client overridable function called before the default treatment of a
     *  valid navigation request. This function can stop the navigation request
     *  if it sets the 'action' field of the request to IgnoreRequest.
     *
     */
    function navigationRequestedDelegate(request) { }

    context: incognito ? SharedWebContext.sharedIncognitoContext : SharedWebContext.sharedContext

    /*
    messageHandlers: [
        Oxide.ScriptMessageHandler {
            msgId: "scroll"
            contexts: ["oxide://selection/"]
            callback: function(msg, frame) {
                internal.dismissCurrentContextualMenu()
            }
        }
    ]
    */

    onNavigationRequested: {
        request.action = WebEngineNavigationRequest.AcceptRequest;
        navigationRequestedDelegate(request);
    }

    /* TODO check how this can be done with QtWebEngine
    preferences.passwordEchoEnabled: Qt.inputMethod.visible
    */

    /* TODO what is this?
    popupMenu: ItemSelector02 {
        webview: _webview
    }
    */

    function copy() {
        console.warn("WARNING: the copy() function is deprecated and does nothing.")
    }

//    touchSelectionController.handle: Image {
//        objectName: "touchSelectionHandle"
//        readonly property int handleOrientation: orientation
//        width: units.gu(1.5)
//        height: units.gu(1.5)
//        source: "handle.png"
//        Component.onCompleted: horizontalPaddingRatio = 0.5
//    }

    Connections {
        target: _webview.touchSelectionController
        onStatusChanged: {
            var status = _webview.touchSelectionController.status
            if (status == Oxide.TouchSelectionController.StatusInactive) {
                quickMenu.visible = false
            } else if (status == Oxide.TouchSelectionController.StatusSelectionActive) {
                quickMenu.visible = true
            }
        }
        onInsertionHandleTapped: quickMenu.visible = !quickMenu.visible
        onContextMenuIntercepted: quickMenu.visible = true
    }

    /* TODO check how copy&paste works in QtWebEngine
    UbuntuShape {
        id: quickMenu
        objectName: "touchSelectionActions"
        visible: false
        opacity: (_webview.activeFocus
                  && (_webview.touchSelectionController.status != Oxide.TouchSelectionController.StatusInactive)
                  && !_webview.touchSelectionController.handleDragInProgress
                  && !selectionOutOfSight) ? 1.0 : 0.0
        aspect: UbuntuShape.DropShadow
        backgroundColor: "white"
        readonly property int padding: units.gu(1)
        width: touchSelectionActionsRow.width + padding * 2
        height: childrenRect.height + padding * 2

        readonly property rect bounds: _webview.touchSelectionController.bounds
        readonly property bool selectionOutOfSight: (bounds.x > _webview.width) || ((bounds.x + bounds.width) < 0) || (bounds.y > _webview.height) || ((bounds.y + bounds.height) < 0)
        readonly property real handleHeight: units.gu(1.5)
        readonly property real spacing: units.gu(1)
        readonly property bool fitsBelow: (bounds.y + bounds.height + handleHeight + spacing + height) <= _webview.height
        readonly property bool fitsAbove: (bounds.y - spacing - height) >= (_webview.locationBarController.height + _webview.locationBarController.offset)
        readonly property real xCentered: bounds.x + (bounds.width - width) / 2
        x: ((xCentered >= 0) && ((xCentered + width) <= _webview.width))
            ? xCentered : (xCentered < 0) ? 0 : _webview.width - width
        y: fitsBelow ? (bounds.y + bounds.height + handleHeight + spacing)
                     : fitsAbove ? (bounds.y - spacing - height)
                                 : (_webview.height + _webview.locationBarController.height + _webview.locationBarController.offset - height) / 2

        ActionList {
            id: touchSelectionActions
            Action {
                name: "selectall"
                text: i18n.dtr('ubuntu-ui-toolkit', "Select All")
                iconName: "edit-select-all"
                enabled: _webview.editingCapabilities & Oxide.WebView.SelectAllCapability
                visible: enabled
                onTriggered: _webview.executeEditingCommand(Oxide.WebView.EditingCommandSelectAll)
            }
            Action {
                name: "cut"
                text: i18n.dtr('ubuntu-ui-toolkit', "Cut")
                iconName: "edit-cut"
                enabled: _webview.editingCapabilities & Oxide.WebView.CutCapability
                visible: enabled
                onTriggered: _webview.executeEditingCommand(Oxide.WebView.EditingCommandCut)
            }
            Action {
                name: "copy"
                text: i18n.dtr('ubuntu-ui-toolkit', "Copy")
                iconName: "edit-copy"
                enabled: _webview.editingCapabilities & Oxide.WebView.CopyCapability
                visible: enabled
                onTriggered: _webview.executeEditingCommand(Oxide.WebView.EditingCommandCopy)
            }
            Action {
                name: "paste"
                text: i18n.dtr('ubuntu-ui-toolkit', "Paste")
                iconName: "edit-paste"
                enabled: _webview.editingCapabilities & Oxide.WebView.PasteCapability
                visible: enabled
                onTriggered: _webview.executeEditingCommand(Oxide.WebView.EditingCommandPaste)
            }
        }

        Row {
            id: touchSelectionActionsRow
            x: parent.padding
            y: parent.padding
            width: {
                // work around what seems to be a bug in Row’s childrenRect.width
                var w = 0
                for (var i in visibleChildren) {
                    w += visibleChildren[i].width
                }
                return w
            }
            height: units.gu(6)

            Repeater {
                model: touchSelectionActions.children
                AbstractButton {
                    objectName: "touchSelectionAction_" + action.name
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: Math.max(units.gu(5), implicitWidth) + units.gu(2)
                    action: modelData
                    styleName: "ToolbarButtonStyle"
                    activeFocusOnPress: false
                    onClicked: _webview.touchSelectionController.hide()
                }
            }
        }
    }
    */

    QtObject {
        id: internal
        property int lastLoadRequestStatus: -1
        property string lastLoadRequestErrorString: ""
        property int lastLoadRequestErrorDomain: -1
        property QtObject contextModel: null

        function dismissCurrentContextualMenu() {
            var model = contextModel
            contextModel = null
            if (model) {
                model.close()
            }
        }

        onContextModelChanged: if (!contextModel) _webview.contextualData.clear()
    }

    readonly property bool lastLoadSucceeded: internal.lastLoadRequestStatus === WebEngineLoadRequest.LoadSucceededStatus
    readonly property bool lastLoadStopped: false // TODO internal.lastLoadRequestStatus === Oxide.LoadEvent.TypeStopped
    readonly property bool lastLoadFailed: internal.lastLoadRequestStatus === WebEngineLoadRequest.LoadFailedStatus
    readonly property string lastLoadRequestErrorString: internal.lastLoadRequestErrorString
    readonly property int lastLoadRequestErrorDomain: internal.lastLoadRequestErrorDomain
    onLoadingChanged: {
        if (loadRequest.errorCode === 420) {
            _webview.stop()
        }
        if ((loadRequest.url === url) && (loadRequest.status !== WebEngineLoadRequest.LoadStartedStatus)) {
            internal.lastLoadRequestStatus = loadRequest.status;
            internal.lastLoadRequestErrorString = loadRequest.errorString;
            internal.lastLoadRequestErrorDomain = loadRequest.errorDomain;
        }
        internal.dismissCurrentContextualMenu();
    }

    readonly property int screenOrientation: Screen.orientation
    onScreenOrientationChanged: {
        internal.dismissCurrentContextualMenu()
    }

    onJavaScriptConsoleMessage: {
        if (_webview.incognito) {
            return
        }

        var msg = "[JS] (%1:%2) %3".arg(sourceID).arg(lineNumber).arg(message)
        if (level === WebEngineView.InfoMessageLevel) {
            console.log(msg)
        } else if (level === WebEngineView.WarningMessageLevel) {
            console.warn(msg)
        } else if (level === WebEngineView.ErrorMessageLevel) {
            console.error(msg)
        }
    }
}
