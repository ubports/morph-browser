/*
 * Copyright 2013-2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import webbrowsercommon.private 0.1
import "actions" as Actions

WebEngineView {
    id: webview
    property var currentWebview: webview
    property ContextMenuRequest contextMenuRequest: null
    
    //enable using plugins, such as widevine or flash, to be installed separate
    settings.pluginsEnabled: true

    property QtObject __ua: UserAgent02 {
    }

    Component.onCompleted: {
        console.log(__ua.defaultUA);
        profile.httpUserAgent = __ua.defaultUA;
    }

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
            var urlRegExp = new RegExp("^https?\:\/\/([^:\/?#]+)");
            var match = urlRegExp.exec(request.url);
            authDialog.host = match[1];
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
    
     onNewViewRequested: function(request) {

         browser.openLinkInNewTabRequested(request.requestedUrl, false);
    }

    function showMessage(text) {

         var alertDialog = PopupUtils.open(Qt.resolvedUrl("AlertDialog.qml"));
         alertDialog.message = text;
     }

    onContextMenuRequested: function(request) {


                request.accepted = true;

                var contextMenu = PopupUtils.open(Qt.resolvedUrl("webbrowser/ContextMenuMobile.qml"));
                contextMenu.actions = contextualactions;

                if (request.linkUrl.toString())
                {
                    contextMenu.titleContent = request.linkUrl;
                }
                else if (request.selectedText)
                {
                    contextMenu.titleContent = request.selectedText;
                }

                contextMenuRequest = request;
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
         /*
            onTriggered: {
                // position the menu target with a one-off assignement instead of a binding
                // since the contents of the contextModel have meaning only while the context
                // menu is active
                //contextualMenuTarget.x = contextModel.position.x
                //contextualMenuTarget.y = contextModel.position.y + locationBarController.height + locationBarController.offset
                internal.addBookmark(contextMenuRequest.linkUrl, contextMenuRequest.linkText, "", contextualMenuTarget)
            }
          */
        }
        Actions.CopyLink {
            objectName: "CopyLinkContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: Clipboard.push(["text/plain", contextMenuRequest.linkUrl.toString()])
        }
        Actions.SaveLink {
            objectName: "SaveLinkContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.linkUrl.toString()
            onTriggered: {showMessage("Actions.SaveLink is not implemented");} //contextModel.saveLink()
        }
        // TODO: not working yet
        Actions.Share {
            objectName: "ShareContextualAction"
            enabled: ( browserTab.contentHandlerLoader && browserTab.contentHandlerLoader.status === Loader.Ready) &&
                      contextMenuRequest && (contextMenuRequest.linkUrl.toString() || contextMenuRequest.selectedText)
            onTriggered: {
                if (contextMenuRequest.linkUrl.toString()) {
                    //internal.shareLink(contextMenuRequest.linkUrl.toString(), contextMenuRequest.linkText)
                    browser.shareLinkRequested(contextMenuRequest.linkUrl.toString(), contextMenuRequest.linkText);
                } else if (contextMenuRequest.selectionText) {
                    //internal.shareText(contextMenuRequest.selectionText)
                    browser.shareTextRequested(contextMenuRequest.selectionText)
                }
            }
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

            // TODO !
            onTriggered: showMessage("Actions.SaveImage not implemented."); //contextModel.saveMedia()
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
                     contextMenuRequest.srcUrl.toString()
            // TODO !
            onTriggered: showMessage("Actions.SaveVideo not implemented."); //contextModel.saveMedia()
        }
        Actions.Undo {
            objectName: "UndoContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                     (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanUndo))
            onTriggered: webview.triggerWebAction(WebEngineView.Undo)
        }
        Actions.Redo {
            objectName: "RedoContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                     (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanRedo))
            onTriggered: webview.triggerWebAction(WebEngineView.Redo)
        }
        Actions.Cut {
            objectName: "CutContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                     (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanCut))
            onTriggered: webview.triggerWebAction(WebEngineView.Cut); //showMessage(contextMenuRequest.editFlags);
        }
        Actions.Copy {
            objectName: "CopyContextualAction"
            enabled: contextMenuRequest && (contextMenuRequest.selectedText || contextMenuRequest.isContentEditable &&
                                      (!contextMenuRequest.editFlags || (contextMenuRequest.editFlag & ContextMenuRequest.CanCopy)))
            onTriggered: webview.triggerWebAction(WebEngineView.Copy)
        }
        Actions.Paste {
            objectName: "PasteContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                     (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanPaste))
            onTriggered: webview.triggerWebAction(WebEngineView.Paste);
        }
        /*
        Actions.Erase {
            objectName: "EraseContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                      (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanDelete))
            // seems not to work
            onTriggered: webview.triggerWebAction(WebEngineView.Delete);
        }
        */
        /*
        does not work correctly (context menu appears again)
        Actions.SelectAll {
            objectName: "SelectAllContextualAction"
            enabled: contextMenuRequest && contextMenuRequest.isContentEditable &&
                     (! contextMenuRequest.editFlags || (contextMenuRequest.editFlags & ContextMenuRequest.CanSelectAll))
            onTriggered: webview.triggerWebAction(WebEngineView.SelectAll);
        }
        */
    }

    
/*
    onFullscreenRequested: webview.fullscreen = fullscreen

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
