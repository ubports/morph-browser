/*
 * Copyright 2016 Canonical Ltd.
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
//import com.canonical.Oxide 1.15 as Oxide
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import "../actions" as Actions
import ".."

WebViewImpl {
    id: webappWebview

    property bool wide: false

    signal openUrlExternallyRequested(string url)

    //filePicker: filePickerLoader.item

    property QtObject contextModel: null
    /*contextualActions: ActionList {
        Actions.OpenLinkInBrowser {
            objectName: "OpenLinkInBrowser"
            enabled: contextModel && contextModel.linkUrl.toString()
            onTriggered: openUrlExternallyRequested(contextModel.linkUrl)
        }
        Actions.CopyLink {
            enabled: contextModel && contextModel.linkUrl.toString()
            onTriggered: Clipboard.push(["text/plain", contextModel.linkUrl.toString()])
            objectName: "CopyLinkContextualAction"
        }
        Actions.SaveLink {
            enabled: contextModel && contextModel.linkUrl.toString()
            onTriggered: contextModel.saveLink()
            objectName: "SaveLinkContextualAction"
        }
        Actions.Share {
            objectName: "ShareContextualAction"
            enabled: (contentHandlerLoader.status == Loader.Ready) && contextModel &&
                     (contextModel.linkUrl.toString() || contextModel.selectionText)
            onTriggered: {
                if (contextModel.linkUrl.toString()) {
                    internal.shareLink(contextModel.linkUrl.toString(), contextModel.linkText)
                } else if (contextModel.selectionText) {
                    internal.shareText(contextModel.selectionText)
                }
            }
        }
        Actions.CopyImage {
            enabled: contextModel &&
                     ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                      (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)) &&
                     contextModel.hasImageContents
            onTriggered: contextModel.copyImage()
            objectName: "CopyImageContextualAction"
        }
        Actions.SaveImage {
            enabled: contextModel &&
                     ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                      (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)) &&
                     contextModel.hasImageContents
            onTriggered: contextModel.saveMedia()
            objectName: "SaveImageContextualAction"
        }
        Actions.Undo {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.UndoCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandUndo)
            objectName: "UndoContextualAction"
        }
        Actions.Redo {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.RedoCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandRedo)
            objectName: "RedoContextualAction"
        }
        Actions.Cut {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.CutCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandCut)
            objectName: "CutContextualAction"
        }
        Actions.Copy {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.CopyCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandCopy)
            objectName: "CopyContextualAction"
        }
        Actions.Paste {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.PasteCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandPaste)
            objectName: "PasteContextualAction"
        }
        Actions.Erase {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.EraseCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandErase)
            objectName: "EraseContextualAction"
        }
        Actions.SelectAll {
            enabled: contextModel &&
                     contextModel.isEditable &&
                     (contextModel.editFlags & Oxide.WebView.SelectAllCapability)
            onTriggered: executeEditingCommand(Oxide.WebView.EditingCommandSelectAll)
            objectName: "SelectAllContextualAction"
        }
    }*/
    function contextMenuOnCompleted(menu) {
        if (!menu || !menu.contextModel) {
            return
        }
        contextModel = menu.contextModel

        var isImageMediaType =
                ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                 (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas))
             && contextModel.hasImageContents;

        if (contextModel.linkUrl.toString() ||
            contextModel.srcUrl.toString() ||
            contextModel.selectionText ||
            (contextModel.isEditable && contextModel.editFlags) ||
            isImageMediaType) {
            menu.show()
        } else {
            contextModel.close()
        }
    }
    Component {
        id: contextMenuNarrowComponent
        ContextMenuMobile {
            actions: contextualActions
            Component.onCompleted: webappWebview.contextMenuOnCompleted(this)
        }
    }
    Component {
        id: contextMenuWideComponent
        ContextMenuWide {
            associatedWebview: webappWebview
            parent: webappWebview
            actions: contextualActions
            Component.onCompleted: webappWebview.contextMenuOnCompleted(this)
        }
    }
    /*contextMenu: webappWebview.wide ? contextMenuWideComponent : contextMenuNarrowComponent

    onGeolocationPermissionRequested: {
        if (__runningConfined && (request.origin == request.embedder)) {
            // When running confined, querying the location service will trigger
            // a system prompt (trust store), so no need for a custom one.
            request.allow()
        } else {
            requestGeolocationPermission(request)
        }
    }*/

    Loader {
        id: contentHandlerLoader
        source: "../ContentHandler.qml"
        asynchronous: true
    }

    QtObject {
        id: internal

        function instantiateShareComponent() {
            var component = Qt.createComponent("../Share.qml")
            if (component.status === Component.Ready) {
                var share = component.createObject(webappWebview)
                share.onDone.connect(share.destroy)
                return share
            }
            return null
        }

        function shareLink(url, title) {
            var share = instantiateShareComponent()
            if (share) share.shareLink(url, title)
        }

        function shareText(text) {
            var share = instantiateShareComponent()
            if (share) share.shareText(text)
        }
    }

    onShowDownloadDialog: {
       if (downloadDialogLoader.status === Loader.Ready) {
           var downloadDialog =
                   PopupUtils.open(downloadDialogLoader.item,
                                   webappWebview,
                                   {"contentType" : contentType,
                                    "downloadId" : downloadId,
                                    "singleDownload" : downloader,
                                    "filename" : filename,
                                    "mimeType" : mimeType})
           downloadDialog.startDownload.connect(startDownload)
        }
    }

    Loader {
        id: downloadDialogLoader
        source: "ContentDownloadDialog.qml"
        asynchronous: true
    }

    Loader {
        id: filePickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }
}
