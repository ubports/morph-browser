/*
 * Copyright 2013-2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.7
import Morph.Web 0.1
import webbrowsercommon.private 0.1
import "actions" as Actions
import "UrlUtils.js" as UrlUtils

WebView {
    id: webview

    // ToDo: does not yet take into account browser zoom and pinch (pinch is not connected to zoomFactor property of WebEngineView
    readonly property real scaleFactor: Screen.devicePixelRatio

    property var currentWebview: webview
    property ContextMenuRequest contextMenuRequest: null

    // scroll positions at the moment of the context menu request
    property point contextMenuStartScroll: Qt.point(0,0)

    // remember certificate errors for each domain (for click on symbol in address bar)
    readonly property var certificateErrorsMap: ({})

    Component.onCompleted: {
        console.log(__ua.defaultUA);
        profile.httpUserAgent = __ua.defaultUA;
    }

    //property real contextMenux: contextMenuRequest.x + (webview.scrollPosition.x - contextMenuStartScroll.x)
    //property real contextMenuy: contextMenuRequest.y + (webview.scrollPosition.y - contextMenuStartScroll.y)

    //enable using plugins, such as widevine or flash, to be installed separate
    settings.pluginsEnabled: true

    /*experimental.certificateVerificationDialog: CertificateVerificationDialog {}
    experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {}*/

    signal showDownloadDialog(string downloadId, var contentType, var downloader, string filename, string mimeType)

    QtObject {
        id: internal

        readonly property var downloadMimeTypesBlacklist: [
            "application/x-shockwave-flash", // http://launchpad.net/bugs/1379806
        ]
    }

    onJavaScriptDialogRequested: function(request) {

        switch (request.type)
        {
            case JavaScriptDialogRequest.DialogTypeAlert:
                request.accepted = true;
                var alertDialog = PopupUtils.open(Qt.resolvedUrl("AlertDialog.qml"));
                alertDialog.message = request.message;
                alertDialog.accept.connect(request.dialogAccept);
                break;

            case JavaScriptDialogRequest.DialogTypeConfirm:
                request.accepted = true;
                var confirmDialog = PopupUtils.open(Qt.resolvedUrl("ConfirmDialog.qml"));
                confirmDialog.message = request.message;
                confirmDialog.accept.connect(request.dialogAccept);
                confirmDialog.reject.connect(request.dialogReject);
                break;

            case JavaScriptDialogRequest.DialogTypePrompt:
                request.accepted = true;
                var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"));
                promptDialog.message = request.message;
                promptDialog.defaultValue = request.defaultText;
                promptDialog.accept.connect(request.dialogAccept);
                promptDialog.reject.connect(request.dialogReject);
                break;

            // did not work with JavaScriptDialogRequest.DialogTypeUnload (the default dialog was shown)
            //case JavaScriptDialogRequest.DialogTypeUnload:
            case 3:
                request.accepted = true;
                var beforeUnloadDialog = PopupUtils.open(Qt.resolvedUrl("BeforeUnloadDialog.qml"));
                beforeUnloadDialog.message = request.message;
                beforeUnloadDialog.accept.connect(request.dialogAccept);
                beforeUnloadDialog.reject.connect(request.dialogReject);
                break;
        }

    }

    onFileDialogRequested: function(request) {

        switch (request.mode)
        {
            case FileDialogRequest.FileModeOpen:
                request.accepted = true;
                var fileDialogSingle = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
                fileDialogSingle.allowMultipleFiles = false;
                fileDialogSingle.accept.connect(request.dialogAccept);
                fileDialogSingle.reject.connect(request.dialogReject);
                break;

            case FileDialogRequest.FileModeOpenMultiple:
                request.accepted = true;
                var fileDialogMultiple = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
                fileDialogMultiple.allowMultipleFiles = true;
                fileDialogMultiple.accept.connect(request.dialogAccept);
                fileDialogMultiple.reject.connect(request.dialogReject);
                break;

            case FilealogRequest.FileModeUploadFolder:
            case FileDialogRequest.FileModeSave:
                request.accepted = false;
                break;
        }

    }

    onColorDialogRequested: function(request) {
        request.accepted = true;
        var colorDialog = PopupUtils.open(Qt.resolvedUrl("ColorSelectDialog.qml"));
        colorDialog.defaultValue = request.color;
        colorDialog.accept.connect(request.dialogAccept);
        colorDialog.reject.connect(request.dialogReject);
        //myDialog.visible = true;
    }

    onAuthenticationDialogRequested: function(request) {

        switch (request.type)
        {
            //case WebEngineAuthenticationDialogRequest.AuthenticationTypeHTTP:
            case 0:
            request.accepted = true;
            var authDialog = PopupUtils.open(Qt.resolvedUrl("HttpAuthenticationDialog.qml"), webview.currentWebview);
            authDialog.host = UrlUtils.extractHost(request.url);
            authDialog.realm = request.realm;
            authDialog.accept.connect(request.dialogAccept);
            authDialog.reject.connect(request.dialogReject);

            break;

            //case WebEngineAuthenticationDialogRequest.AuthenticationTypeProxy:
            case 1:
            request.accepted = false;
            break;
        }

    }

     onFeaturePermissionRequested: {

         switch(feature)
         {
             case WebEngineView.Geolocation:

             // TODO: we might want to store the answer to avoid requesting
             // the permission everytime the user visits this site.
             var geoPermissionDialog = PopupUtils.open(Qt.resolvedUrl("GeolocationPermissionRequest.qml"));
             geoPermissionDialog.origin = securityOrigin;
             geoPermissionDialog.feature = feature;
             break;

             case WebEngineView.MediaAudioCapture:
             case WebEngineView.MediaVideoCapture:
             case WebEngineView.MediaAudioVideoCapture:

             var mediaAccessDialog = PopupUtils.open(Qt.resolvedUrl("MediaAccessDialog.qml"));
             mediaAccessDialog.origin = securityOrigin;
             mediaAccessDialog.feature = feature;
             break;
         }
    }

      onCertificateError: function(certificateError) {

          certificateError.defer()
          var certificateVerificationDialog = PopupUtils.open(Qt.resolvedUrl("CertificateVerificationDialog.qml"));
          certificateVerificationDialog.host = UrlUtils.extractHost(certificateError.url);
          certificateErrorsMap[certificateVerificationDialog.host] = certificateError
          certificateErrorsMapChanged()
          certificateVerificationDialog.localizedErrorMessage = certificateError.description
          certificateVerificationDialog.errorIsOverridable = certificateError.overridable
          certificateVerificationDialog.accept.connect(certificateError.ignoreCertificateError)
          certificateVerificationDialog.reject.connect(certificateError.rejectCertificate)
      }


     onNewViewRequested: function(request) {

         browser.openLinkInNewTabRequested(request.requestedUrl, false);
    }

    function showMessage(text) {

         var alertDialog = PopupUtils.open(Qt.resolvedUrl("AlertDialog.qml"));
         alertDialog.message = text;
     }

    QtObject {
        id: domElementOfContextMenu

        // true for input and textarea elements that support text selection
        property bool hasSelectMethod: false
        property bool isDocumentElement: false
    }

    onContextMenuRequested: function(request) {

                contextMenuRequest = request;
                //console.log("onContextMenuRequested, request: " + JSON.stringify(request))
                request.accepted = true;

                if (request.linkUrl.toString() || request.mediaType)
                {
                    var contextMenu = PopupUtils.open(Qt.resolvedUrl("webbrowser/ContextMenuMobile.qml"));
                    contextMenu.actions = contextualactions;
                    contextMenu.titleContent = request.linkUrl;
                }
                else
                {
                    contextMenuStartScroll.x = webview.scrollPosition.x;
                    contextMenuStartScroll.y = webview.scrollPosition.y;
                    quickMenu.selectedTextLength = contextMenuRequest.selectedText.length
                    quickMenu.textSelectionLevels = []
                    quickMenu.textSelectionIsAtRootLevel = false

                    var commandGetContextMenuInfo = "
                    var morphElemContextMenu = document.elementFromPoint(%1, %2);
                    var morphContextMenuIsDocumentElement = false;
                    if (morphElemContextMenu === null)
                    {
                        morphElemContextMenu = document.documentElement;
                        morphContextMenuIsDocumentElement = true;
                    }
                    var morphContextMenuElementHasSelectMethod = (typeof morphElemContextMenu.select === 'function') ? true : false;
                    // result array
                    // [0]..[3] : bounds of the selected element
                    // [4] : boolean variable morphContextMenuIsDocumentElement
                    // [5] : boolean variable morphContextMenuElementHasSelectMethod
                    //    true: context menu for the whole HTML document
                    //    false: context menu for a specific element (e.g. input, span, ...)
                    [morphElemContextMenu.offsetLeft, morphElemContextMenu.offsetTop, morphElemContextMenu.offsetWidth, morphElemContextMenu.offsetHeight, morphContextMenuIsDocumentElement, morphContextMenuElementHasSelectMethod];
                    ".arg(request.x).arg(request.y)

                    webview.runJavaScript(commandGetContextMenuInfo, function(result)
                                                            {
                                                               console.log("commandGetContextMenuInfo returned array " + JSON.stringify(result))
                                                               quickMenu.bounds = Qt.rect(result[0], result[1], result[2], result[3])
                                                               domElementOfContextMenu.isDocumentElement = result[4]
                                                               domElementOfContextMenu.hasSelectMethod = result[5]
                                                            }
                                         );
                    quickMenu.visible = true;
                }
   }

    ActionList {

        id: contextualactions
        Actions.OpenLinkInNewTab {
            objectName: "OpenLinkInNewTabContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            //onTriggered: browser.internal.openUrlInNewTab(contextMenuRequest.linkUrl, true, true, tabsModel.indexOf(browserTab) + 1)
            onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.linkUrl, false);
        }
        Actions.OpenLinkInNewBackgroundTab {
            objectName: "OpenLinkInNewBackgroundTabContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            //onTriggered: internal.openUrlInNewTab(contextMenuRequest.linkUrl, false, true, tabsModel.indexOf(browserTab) + 1)
            onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.linkUrl, true);
        }
        Actions.OpenLinkInNewWindow {
            objectName: "OpenLinkInNewWindowContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: browser.openLinkInWindowRequested(contextMenuRequest.linkUrl, false)
        }
        Actions.OpenLinkInPrivateWindow {
            objectName: "OpenLinkInPrivateWindowContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: browser.openLinkInWindowRequested(contextMenuRequest.linkUrl, true)
        }
        Actions.BookmarkLink {
            objectName: "BookmarkLinkContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString() && !BookmarksModel.contains(contextMenuRequest.linkUrl)
            onTriggered: showMessage("Actions.BookmarkLink not implemented.");
        }
        Actions.CopyLink {
            objectName: "CopyLinkContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: Clipboard.push(["text/plain", contextMenuRequest.linkUrl.toString()])
        }
        Actions.SaveLink {
            objectName: "SaveLinkContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: webview.triggerWebAction(WebEngineView.DownloadLinkToDisk)
        }
        Actions.Share {
            objectName: "ShareContextualAction"
            enabled: ( browserTab && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready) &&
                     contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: browser.shareLinkRequested(contextMenuRequest.linkUrl.toString(), contextMenuRequest.linkText);
        }
        Actions.OpenImageInNewTab {
            objectName: "OpenImageInNewTabContextualAction"
            enabled:   contextMenuRequest &&
                       (contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeImage) &&
                       contextMenuRequest.mediaUrl.toString()
            //onTriggered: internal.openUrlInNewTab(contextModel.srcUrl, true, true, tabsModel.indexOf(browserTab) + 1)
            onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.mediaUrl, false);
        }
        Actions.CopyImage {
            objectName: "CopyImageContextualAction"
            enabled:  contextMenuRequest &&
                      ((contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeImage) ||
                       (contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeCanvas )) // && contextModel.hasImageContents
            // TODO !
            onTriggered: showMessage("Actions.CopyImage not implemented."); //contextModel.saveMedia()
        }
        Actions.SaveImage {
            objectName: "SaveImageContextualAction"
            enabled: contextMenuRequest &&
                     ((contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeImage) ||
                      (contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeCanvas)) // && contextModel.hasImageContents

            onTriggered: webview.triggerWebAction(WebEngineView.DownloadImageToDisk)
        }
        Actions.OpenVideoInNewTab {
            objectName: "OpenVideoInNewTabContextualAction"
            enabled: contextMenuRequest &&
                     (contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeVideo) &&
                     contextMenuRequest.mediaUrl.toString()
            //onTriggered: internal.openUrlInNewTab(contextMenuRequest.srcUrl, true, true, tabsModel.indexOf(browserTab) + 1)
            onTriggered: browser.openLinkInNewTabRequested(contextMenuRequest.mediaUrl, false);
        }
        Actions.SaveVideo {
            objectName: "SaveVideoContextualAction"
            enabled: contextMenuRequest &&
                     (contextMenuRequest.mediaType === ContextMenuRequest.MediaTypeVideo) &&
                     contextMenuRequest.mediaUrl.toString()
            onTriggered: webview.triggerWebAction(WebEngineView.DownloadMediaToDisk)
        }
        Actions.Copy {
            objectName: "CopyContextualAction"
            enabled: contextMenuRequest && ( (quickMenu.selectedTextLength > 0) || (contextMenuRequest.editFlags && ContextMenuRequest.CanCopy))
            onTriggered: webview.triggerWebAction(WebEngineView.Copy)
        }
    }

    UbuntuShape {
            z:3
            id: quickMenu
            objectName: "touchSelectionActions"
            visible: false
            //opacity: (_webview.activeFocus
            //          && (_webview.touchSelectionController.status != Oxide.TouchSelectionController.StatusInactive)
            //          && !_webview.touchSelectionController.handleDragInProgress
            //          && !selectionOutOfSight) ? 1.0 : 0.0
            aspect: UbuntuShape.DropShadow
            backgroundColor: "white"
            readonly property int padding: units.gu(1)
            width: touchSelectionActionsRow.width + padding * 2
            height: childrenRect.height + padding * 2

            readonly property point webViewScrollPosition: visible ? webview.scrollPosition : Qt.point(0,0)
            property rect bounds: Qt.rect(10,10,10,10)
            readonly property bool selectionVerticallyOutOfSight: (bounds.y > webview.height + webViewScrollPosition.y / scaleFactor) || ((bounds.y + bounds.height) < webViewScrollPosition.y / scaleFactor)
            readonly property real handleHeight: 0 // units.gu(1.5)
            readonly property real spacing: units.gu(0.5)
            readonly property bool fitsBelow: (bounds.y - contextMenuStartScroll.y / scaleFactor + bounds.height + handleHeight + spacing + height - (webViewScrollPosition.y - contextMenuStartScroll.y) / scaleFactor) <= webview.height - Qt.inputMethod.keyboardRectangle.height / scaleFactor
            readonly property bool fitsAbove: (bounds.y - contextMenuStartScroll.y / scaleFactor - spacing - height - (webViewScrollPosition.y - contextMenuStartScroll.y) / scaleFactor) >= 0
            readonly property real xCentered: bounds.x + (bounds.width - width) / 2
            property int selectedTextLength: 0
            // remember previous text selection levels in an first in - first out array
            property var textSelectionLevels: []
            property bool textSelectionIsAtRootLevel: false

            x: ((xCentered >= 0) && ((xCentered + width) <= webview.width))
                ? xCentered : (xCentered < 0) ? 0 : webview.width - width
            y: (fitsBelow && ! selectionVerticallyOutOfSight && ! domElementOfContextMenu.isDocumentElement) ? (bounds.y - contextMenuStartScroll.y / scaleFactor + bounds.height + handleHeight + spacing - (webViewScrollPosition.y - contextMenuStartScroll.y) / scaleFactor )
                         : (fitsAbove && ! selectionVerticallyOutOfSight && ! domElementOfContextMenu.isDocumentElement) ? (bounds.y - contextMenuStartScroll.y / scaleFactor - spacing - height - (webViewScrollPosition.y - contextMenuStartScroll.y) / scaleFactor)
                                     : (webview.height - height) / 2

            ActionList {
                id: touchSelectionActions

                // text selection with <leafElementName> as starting point
                function extendSelectionUpTheDom (leafElementName) {

                    var commandExtendSelection = "
            var elementForTextSelection = %1;
            var selectedLengthStart = window.getSelection().toString().length;

            var levelCounter = 0;
            // go up the DOM until the selection is larger
            while (elementForTextSelection.parentNode)
            {
                // select the current node
                var range = document.createRange();
                range.selectNode(elementForTextSelection);
                window.getSelection().removeAllRanges();
                window.getSelection().addRange(range);

                if (window.getSelection().toString().length > selectedLengthStart)
                {
                    break;
                }
                elementForTextSelection = elementForTextSelection.parentNode;
                levelCounter++;
            }

            // return array
            // [0] length of selection
            // [1] parent level at end
            // [2] isRootNode
            [window.getSelection().toString().length, levelCounter, elementForTextSelection.parentNode ? false : true]
            ".arg(leafElementName);

            webview.runJavaScript(commandExtendSelection,
                                  function(result) {
                                      console.log("[extendSelectionUpTheDom] java script function returned " + JSON.stringify(result))
                                      var selectedLength = result[0]
                                      var parentLevelAtEnd = result[1]
                                      var isRootNode = result[2]
                                      quickMenu.selectedTextLength = selectedLength
                                      while (quickMenu.textSelectionLevels.length > 0 && (parentLevelAtEnd <= quickMenu.textSelectionLevels[quickMenu.textSelectionLevels.length - 1] ))
                                      {
                                          quickMenu.textSelectionLevels.pop()
                                      }
                                      quickMenu.textSelectionLevels.push(parentLevelAtEnd)
                                      quickMenu.textSelectionLevelsChanged()
                                      console.log("quickMenu.textSelectionLevels is now " + JSON.stringify(quickMenu.textSelectionLevels))
                                      quickMenu.textSelectionIsAtRootLevel = isRootNode
                                 });
            }

            // <parentLevel> how many levels (.parentNode calls) to go up to reach the node with the text selection in the DOM
            // <leafElementName> is the starting point (element the context menu was created for)
            function setTextSelection (leafElementName, parentLevel) {

                    var commandSetTextSelection = "
            var elementForTextSelection = %1;
            var parentLevel = %2;

            var levelCounter = 0;
            while (elementForTextSelection.parentNode && (levelCounter < parentLevel))
            {
                elementForTextSelection = elementForTextSelection.parentNode;
                levelCounter++;
            }

            var range = document.createRange();
            range.selectNode(elementForTextSelection);
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(range);

            // return length of selection
            window.getSelection().toString().length
            ".arg(leafElementName).arg(parentLevel);

            webview.runJavaScript(commandSetTextSelection,
                                  function(result) {
                                      console.log("the length of selection is now " + result)
                                      quickMenu.selectedTextLength = result
                                      quickMenu.textSelectionLevels.pop()
                                      quickMenu.textSelectionLevelsChanged()
                                      console.log("quickMenu.textSelectionLevels is now " + JSON.stringify(quickMenu.textSelectionLevels))
                                      quickMenu.textSelectionIsAtRootLevel = false
                                  });
            }

            Action {
                    name: "undo"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Undo")
                    iconName: "edit-undo"
                    // with the editFlags we would have to close the context menu after one "Undo" step (desktop way)
                    // after one action we do no longer know if further Undo actions are possible
                    // if we keep the button enabled, the user can use Undo/Redo multiple times
                    enabled: visible // && (contextMenuRequest.editFlags & ContextMenuRequest.CanUndo)
                    visible: contextMenuRequest && contextMenuRequest.isContentEditable
                    onTriggered: {
                        webview.triggerWebAction(WebEngineView.Undo)
                        // ToDo: might there be a way to refresh / recreate the context menu again (for the same element) without user interaction,
                        // so that the editFlags are updated, then we could use the editFlags for the enabled property
                        // with JavaScript it seems not possible: https://stackoverflow.com/a/1241569/4326472
                    }
                }
                Action {
                    name: "redo"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Redo")
                    iconName: "edit-redo"
                    // with the editFlags we would have to close the context menu after one "Redo" step (desktop way)
                    // see comment for "Undo"
                    enabled: visible // && (contextMenuRequest.editFlags & ContextMenuRequest.CanRedo)
                    visible: contextMenuRequest && contextMenuRequest.isContentEditable
                    onTriggered: {
                        webview.triggerWebAction(WebEngineView.Redo)
                    }
                }
                Action {
                    name: "selectless"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Select Less")
                    iconName: "edit-select-all"
                    enabled: visible && quickMenu.textSelectionLevels.length > 1
                    visible: contextMenuRequest && ! domElementOfContextMenu.isDocumentElement && ! domElementOfContextMenu.hasSelectMethod
                    onTriggered: touchSelectionActions.setTextSelection("morphElemContextMenu", quickMenu.textSelectionLevels[quickMenu.textSelectionLevels.length - 2])
                }
                Action {
                    name: "selectmore"
                    text: (quickMenu.textSelectionLevels.length == 0)    ? i18n.dtr('ubuntu-ui-toolkit', "Select Element")
                                                                         :  i18n.dtr('ubuntu-ui-toolkit', "Select More")
                    iconName: "edit-select-all"
                    enabled: visible && ! quickMenu.textSelectionIsAtRootLevel
                    visible: contextMenuRequest && ! domElementOfContextMenu.isDocumentElement && ! domElementOfContextMenu.hasSelectMethod
                    onTriggered: touchSelectionActions.extendSelectionUpTheDom("morphElemContextMenu")
                }
                Action {
                    name: "selectall"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Select All")
                    iconName: "edit-select-all"
                    // can we make it so that it only appears for non-empty inputs ?
                    enabled: contextMenuRequest && (contextMenuRequest.editFlags & ContextMenuRequest.CanSelectAll)
                    visible: enabled
                    onTriggered: {
                        // in some cases this command creates a new contextMenuRequest, in others not
                        // for the second case, set the document mode here as well
                        if (! domElementOfContextMenu.hasSelectMethod)
                        {
                            domElementOfContextMenu.isDocumentElement = true
                        }
                        webview.triggerWebAction(WebEngineView.SelectAll);
                    }
                }
                Action {
                    name: "cut"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Cut")
                    iconName: "edit-cut"
                    enabled: contextMenuRequest && contextMenuRequest.isContentEditable && quickMenu.selectedTextLength > 0
                    visible: enabled
                    onTriggered: {
                       quickMenu.visible = false;
                       webview.triggerWebAction(WebEngineView.Cut);
                    }
                }
                Action {
                    name: "copy"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Copy")
                    iconName: "edit-copy"
                    enabled: contextMenuRequest && quickMenu.selectedTextLength > 0
                    visible: enabled
                    onTriggered: {
                        quickMenu.visible = false;
                        webview.triggerWebAction(WebEngineView.Copy)
                    }
                }
                Action {
                    name: "paste"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Paste")
                    iconName: "edit-paste"
                    enabled: contextMenuRequest && contextMenuRequest.isContentEditable && (contextMenuRequest.editFlags & ContextMenuRequest.CanPaste)
                    visible: enabled
                    onTriggered: {
                        quickMenu.visible = false;
                        webview.triggerWebAction(WebEngineView.Paste);
                    }
                }
                Action {
                    name: "share"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Share")
                    iconName: "share"
                    enabled: ( browserTab && browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready) &&
                              contextMenuRequest && contextMenuRequest.selectedText
                    visible: enabled
                    onTriggered: {
                            browser.shareTextRequested(contextMenuRequest.selectedText)
                    }
                }
                // only needed as long as we don't detect the "blur" event of the control
                // -> try to get that via WebChannel / other mechanism and hide the quickMenu automatically if control has no longer focus
                Action {
                    name: "cancel"
                    text: i18n.dtr('ubuntu-ui-toolkit', "Cancel")
                    iconName: "cancel"
                    enabled: true
                    visible: enabled
                    onTriggered: {
                        quickMenu.visible = false;
                    }
                }
            }

            MouseArea {
                // without that MouseArea the user can click "through" actions with enabled=false (e.g. accidently change the text selection)
                anchors.fill: touchSelectionActionsRow
                onClicked: console.log("inactive touch selection item clicked.")
            }

            Row {
                id: touchSelectionActionsRow
                x: parent.padding
                y: parent.padding
                height: units.gu(6)

                Repeater {
                    model: touchSelectionActions.children
                    AbstractButton {
                        objectName: "touchSelectionAction_" + action.name
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: Math.max(units.gu(4), implicitWidth) + units.gu(1)
                        action: modelData
                        styleName: "ToolbarButtonStyle"
                        activeFocusOnPress: false
                    }
                }
            }
        }

    onNavigationRequested: function (request) {
        quickMenu.visible = false;
        request.action = WebEngineNavigationRequest.AcceptRequest;
    }

    onFullScreenRequested: function(request) {
       browser.fullScreenRequested(request.toggleOn);
       request.accept();
   }
/*
    onDownloadRequested: {
        if (!request.suggestedFilename && request.mimeType &&
            internal.downloadMimeTypesBlacklist.indexOf(request.mimeType) > -1) {
            return
        }

        if (downloadLoader.status == Loader.Ready) {
            var headers = { }
            if (request.cookies.length > 0) {
                headers["Cookie"] = request.cookies.join(";")
            }
            if (request.referrer) {
                headers["Referer"] = request.referrer
            }
            headers["User-Agent"] = webview.context.userAgent
            // Work around https://launchpad.net/bugs/1487090 by guessing the mime type
            // from the suggested filename or URL if oxide hasn’t provided one, or if
            // the server has provided the generic application/octet-stream mime type.
            var mimeType = request.mimeType
            if (!mimeType || mimeType == "application/octet-stream") {
                mimeType = MimeDatabase.filenameToMimeType(request.suggestedFilename)
            }
            if (!mimeType) {
                var scheme = request.url.toString().split('://').shift().toLowerCase()
                var filename = request.url.toString().split('/').pop().split('?').shift()
                if ((scheme == "file") || (filename.indexOf('.') > -1)) {
                    mimeType = MimeDatabase.filenameToMimeType(filename)
                }
            }
            downloadLoader.item.downloadMimeType(request.url, mimeType, headers, request.suggestedFilename, incognito)
        } else {
            // Desktop form factor case
            Qt.openUrlExternally(request.url)
        }
    }
*/


    Loader {
        id: downloadLoader
        source: "Downloader.qml"
        asynchronous: true
    }

/*    Connections {
        target: downloadLoader.item
        onShowDownloadDialog: {
            showDownloadDialog(downloadId, contentType, downloader, filename, mimeType)
        }
    } */
}
