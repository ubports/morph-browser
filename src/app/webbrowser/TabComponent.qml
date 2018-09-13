/*
 * Copyright 2014-2017 Canonical Ltd.
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
//import com.canonical.Oxide 1.15 as Oxide
import webbrowserapp.private 0.1
import "../actions" as Actions
import ".."

// FIXME: This component breaks encapsulation: it uses variables not defined in
// itself. However this is an acceptable tradeoff with regards to
// startup time performance. Indeed having this component defined as a separate
// QML file as opposed to inline makes it possible to cache its compiled form.

Component {
    id: tabComponent

    BrowserTab {
        id: browserTab
        anchors.fill: parent
        incognito: browser ? browser.incognito : false
        current: browser ? browser.tabsModel && browser.tabsModel.currentTab === this : false
        focus: current

        property var bottomEdgeHandle
        property var browser
        property var chrome
        property var chromeController
        property var contentHandlerLoader
        property var downloadDialogLoader
        property var downloadsViewLoader
        property var filePickerLoader
        property var internal
        property var recentView
        property var tabsModel

        Item {
            id: contextualMenuTarget
            visible: false
        }

        webviewComponent: WebViewImpl {
            id: webviewimpl

            property BrowserTab tab
            readonly property bool current: tab.current

            currentWebview: browser ? browser.currentWebview : null
            //filePicker: filePickerLoader ? filePickerLoader.item : null

            anchors.fill: parent

            focus: true

            enabled: current && !bottomEdgeHandle.dragging && !recentView.visible && parent.focus
            /*
            locationBarController {
                height: chrome ? chrome.height : 0
                mode: chromeController ? chromeController.defaultMode : null
            }
            
            */

            //experimental.preferences.developerExtrasEnabled: developerExtrasEnabled
            //preferences.localStorageEnabled: true
            //preferences.appCacheEnabled: true

            //property QtObject contextModel: null
            //contextualActions: 

            /*
             
            ActionList {
                Actions.OpenLinkInNewTab {
                    objectName: "OpenLinkInNewTabContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: internal.openUrlInNewTab(contextModel.linkUrl, true,
                                                          true, tabsModel.indexOf(browserTab) + 1)
                }
                Actions.OpenLinkInNewBackgroundTab {
                    objectName: "OpenLinkInNewBackgroundTabContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: internal.openUrlInNewTab(contextModel.linkUrl, false,
                                                          true, tabsModel.indexOf(browserTab) + 1)
                }
                Actions.OpenLinkInNewWindow {
                    objectName: "OpenLinkInNewWindowContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: browser.openLinkInWindowRequested(contextModel.linkUrl, false)
                }
                Actions.OpenLinkInPrivateWindow {
                    objectName: "OpenLinkInPrivateWindowContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: browser.openLinkInWindowRequested(contextModel.linkUrl, true)
                }
                Actions.BookmarkLink {
                    objectName: "BookmarkLinkContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                             && !BookmarksModel.contains(contextModel.linkUrl)
                    onTriggered: {
                        // position the menu target with a one-off assignement instead of a binding
                        // since the contents of the contextModel have meaning only while the context
                        // menu is active
                        contextualMenuTarget.x = contextModel.position.x
                        contextualMenuTarget.y = contextModel.position.y + locationBarController.height + locationBarController.offset
                        internal.addBookmark(contextModel.linkUrl, contextModel.linkText,
                                             "", contextualMenuTarget)
                    }
                }
                Actions.CopyLink {
                    objectName: "CopyLinkContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: Clipboard.push(["text/plain", contextModel.linkUrl.toString()])
                }
                Actions.SaveLink {
                    objectName: "SaveLinkContextualAction"
                    enabled: contextModel && contextModel.linkUrl.toString()
                    onTriggered: contextModel.saveLink()
                }
                Actions.Share {
                    objectName: "ShareContextualAction"
                    enabled: (contentHandlerLoader && contentHandlerLoader.status == Loader.Ready) && contextModel &&
                             (contextModel.linkUrl.toString() || contextModel.selectionText)
                    onTriggered: {
                        if (contextModel.linkUrl.toString()) {
                            internal.shareLink(contextModel.linkUrl.toString(), contextModel.linkText)
                        } else if (contextModel.selectionText) {
                            internal.shareText(contextModel.selectionText)
                        }
                    }
                }
                Actions.OpenImageInNewTab {
                    objectName: "OpenImageInNewTabContextualAction"
                    enabled: contextModel && false
                    //         (contextModel.mediaType === Oxide.WebView.MediaTypeImage) &&
                    //         contextModel.srcUrl.toString()
                    onTriggered: internal.openUrlInNewTab(contextModel.srcUrl, true,
                                                          true, tabsModel.indexOf(browserTab) + 1)
                }
                Actions.CopyImage {
                    objectName: "CopyImageContextualAction"
                    enabled: contextModel && false
                    //         ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                    //          (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)) &&
                    //         contextModel.hasImageContents
                    onTriggered: contextModel.copyImage()
                }
                Actions.SaveImage {
                    objectName: "SaveImageContextualAction"
                    enabled: contextModel && false
                    //         ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                    //          (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)) &&
                    //         contextModel.hasImageContents
                    onTriggered: contextModel.saveMedia()
                }
                Actions.OpenVideoInNewTab {
                    objectName: "OpenVideoInNewTabContextualAction"
                    enabled: contextModel && false
                    //         (contextModel.mediaType === Oxide.WebView.MediaTypeVideo) &&
                    //         contextModel.srcUrl.toString()
                    onTriggered: internal.openUrlInNewTab(contextModel.srcUrl, true,
                                                          true, tabsModel.indexOf(browserTab) + 1)
                }
                Actions.SaveVideo {
                    objectName: "SaveVideoContextualAction"
                    enabled: contextModel && false
                    //         (contextModel.mediaType === Oxide.WebView.MediaTypeVideo) &&
                    //         contextModel.srcUrl.toString()
                    onTriggered: contextModel.saveMedia()
                }
                Actions.Undo {
                    objectName: "UndoContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.UndoCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandUndo)
                }
                Actions.Redo {
                    objectName: "RedoContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.RedoCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandRedo)
                }
                Actions.Cut {
                    objectName: "CutContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.CutCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandCut)
                }
                Actions.Copy {
                    objectName: "CopyContextualAction"
                    enabled: contextModel && (contextModel.selectionText ||
                                              (contextModel.isEditable && false))
                    //                           (contextModel.editFlags & Oxide.WebView.CopyCapability)))
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandCopy)
                }
                Actions.Paste {
                    objectName: "PasteContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.PasteCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandPaste)
                }
                Actions.Erase {
                    objectName: "EraseContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.EraseCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandErase)
                }
                Actions.SelectAll {
                    objectName: "SelectAllContextualAction"
                    enabled: contextModel && contextModel.isEditable && false
                    //         (contextModel.editFlags & Oxide.WebView.SelectAllCapability)
                    //onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandSelectAll)
                }
            }

            function contextMenuOnCompleted(menu) {
                contextModel = menu.contextModel
                if (contextModel.linkUrl.toString() ||
                        contextModel.srcUrl.toString() ||
                        contextModel.selectionText ||
                        (contextModel.isEditable && contextModel.editFlags) || (false &&
                    //    (((contextModel.mediaType == Oxide.WebView.MediaTypeImage) ||
                    //      (contextModel.mediaType == Oxide.WebView.MediaTypeCanvas)) &&
                         contextModel.hasImageContents)) {
                    menu.show()
                } else {
                    contextModel.close()
                }
            }
            
            Component {
                id: contextMenuNarrowComponent
                ContextMenuMobile {
                    actions: contextualActions
                    Component.onCompleted: webviewimpl.contextMenuOnCompleted(this)
                }
            }
            Component {
                id: contextMenuWideComponent
                ContextMenuWide {
                    webview: webviewimpl
                    parent: browser
                    actions: contextualActions
                    Component.onCompleted: webviewimpl.contextMenuOnCompleted(this)
                }
            }
            */
            
            //contextMenu: browser && browser.wide ? contextMenuWideComponent : contextMenuNarrowComponent
            /*
            onNewViewRequested: {
                var newTab = browser.createTab({"request": request})
                var setCurrent = true//(request.disposition == Oxide.NewViewRequest.DispositionNewForegroundTab)
                internal.addTab(newTab, setCurrent, tabsModel.indexOf(browserTab) + 1)
                if (setCurrent) tabContainer.forceActiveFocus()
            }

            onCloseRequested: prepareToClose()
            onPrepareToCloseResponse: {
                if (proceed) {
                    if (tab) {
                        var i = tabsModel.indexOf(tab);
                        if (i != -1) {
                            tabsModel.remove(i);
                        }

                        // tab.close() destroys the context so add new tab before destroy if required
                        if (tabsModel.count === 0) {
                            internal.openUrlInNewTab("", true, true)
                        }

                        tab.close()
                    } else if (tabsModel.count === 0) {
                        internal.openUrlInNewTab("", true, true)
                    }
                }
            }
*/
            QtObject {
                id: webviewInternal
                property url storedUrl: ""
                property bool titleSet: false
                property string title: ""
            }
            /*
            onLoadEvent: {
              //  if (event.type == Oxide.LoadEvent.TypeCommitted) {
              //      chrome.findInPageMode = false
              //      webviewInternal.titleSet = false
              //      webviewInternal.title = title
              //  }

                if (webviewimpl.incognito) {
                    return
                }

              //  if ((event.type == Oxide.LoadEvent.TypeCommitted) &&
              //          !event.isError &&
              //          (300 > event.httpStatusCode) && (event.httpStatusCode >= 200)) {
              //      webviewInternal.storedUrl = event.url
              //      HistoryModel.add(event.url, title, icon)
              //  }

                // If the page has started, stopped, redirected, errored
                // then clear the cache for the history update
                // Otherwise if no title change has occurred the next title
                // change will be the url of the next page causing the
                // history entry to be incorrect (pad.lv/1603835)
              //  if (event.type == Oxide.LoadEvent.TypeFailed ||
              //          event.type == Oxide.LoadEvent.TypeRedirected ||
              //          event.type == Oxide.LoadEvent.TypeStarted ||
              //          event.type == Oxide.LoadEvent.TypeStopped) {
              //      webviewInternal.titleSet = true
              //      webviewInternal.storedUrl = ""
              //  }
            }
            onTitleChanged: {
                if (!webviewInternal.titleSet && webviewInternal.storedUrl.toString()) {
                    // Record the title to avoid updating the history database
                    // every time the page dynamically updates its title.
                    // We don’t want pages that update their title every second
                    // to achieve an ugly "scrolling title" effect to flood the
                    // history database with updates.
                    webviewInternal.titleSet = true
                    if (webviewInternal.title != title) {
                        webviewInternal.title = title
                        HistoryModel.update(webviewInternal.storedUrl, title, icon)
                    }
                }
            }
            onIconChanged: {
                if (webviewInternal.storedUrl.toString()) {
                    HistoryModel.update(webviewInternal.storedUrl, webviewInternal.title, icon)
                }
            }

            //onGeolocationPermissionRequested: requestGeolocationPermission(request)
*/
            property var certificateError
            function resetCertificateError() {
                certificateError = null
            }
            /*
            onCertificateError: {
                if (!error.isMainFrame || error.isSubresource) {
                    // Not a main frame document error, just block the content
                    // (it’s not overridable anyway).
                    return
                }
                if (internal.isCertificateErrorAllowed(error)) {
                    error.allow()
                } else {
                    certificateError = error
                    error.onCancelled.connect(webviewimpl.resetCertificateError)
                }
            }

            //onFullscreenChanged: {
            //    if (fullscreen) {
            //        fullscreenExitHintComponent.createObject(webviewimpl)
            //    }
            //}
            */
            Component {
                id: fullscreenExitHintComponent

                Rectangle {
                    id: fullscreenExitHint
                    objectName: "fullscreenExitHint"

                    anchors.centerIn: parent
                    height: units.gu(6)
                    width: Math.min(units.gu(50), parent.width - units.gu(12))
                    radius: units.gu(1)
                    color: "#3e3b39"
                    opacity: 0.85

                    Behavior on opacity {
                        UbuntuNumberAnimation {
                            duration: UbuntuAnimation.SlowDuration
                        }
                    }
                    onOpacityChanged: {
                        if (opacity == 0.0) {
                            fullscreenExitHint.destroy()
                        }
                    }

                    // Delay showing the hint to prevent it from jumping up while the
                    // webview is being resized (https://launchpad.net/bugs/1454097).
                    visible: false
                    Timer {
                        running: true
                        interval: 250
                        onTriggered: fullscreenExitHint.visible = true
                    }

                    Label {
                        color: "white"
                        font.weight: Font.Light
                        anchors.centerIn: parent
                        text: bottomEdgeHandle.enabled
                              ? i18n.tr("Swipe Up To Exit Full Screen")
                              : i18n.tr("Press ESC To Exit Full Screen")
                    }

                    Timer {
                        running: fullscreenExitHint.visible
                        interval: 2000
                        onTriggered: fullscreenExitHint.opacity = 0
                    }

                    Connections {
                        target: webviewimpl
                      //  onFullscreenChanged: {
                      //      if (!webviewimpl.fullscreen) {
                      //          fullscreenExitHint.destroy()
                      //      }
                      //  }
                    }

                    Component.onCompleted: bottomEdgeHint.forceShow = true
                    Component.onDestruction: bottomEdgeHint.forceShow = false
                }
            }
/*
            onShowDownloadDialog: {
                if (downloadDialogLoader.status === Loader.Ready) {
                    var downloadDialog = PopupUtils.open(downloadDialogLoader.item, browser, {"contentType" : contentType,
                                                             "downloadId" : downloadId,
                                                             "singleDownload" : downloader,
                                                             "filename" : filename,
                                                             "mimeType" : mimeType})
                    downloadDialog.startDownload.connect(startDownload)
                }
            }
            */

            function showDownloadsPage() {
                downloadsViewLoader.active = true
                return downloadsViewLoader.item
            }

            function startDownload(downloadId, download, mimeType) {
                DownloadsModel.add(downloadId, download.url, mimeType, incognito)
                download.start()
                downloadsViewLoader.active = true
            }

        }
    }
}
