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
import Ubuntu.Components 0.1
import webbrowserapp.private 0.1
import "../actions" as Actions
import ".."

BrowserView {
    id: browser

    property alias currentIndex: tabsModel.currentIndex
    currentWebview: tabsModel.currentWebview

    property QtObject searchEngine

    actions: [
        Actions.GoTo {
            onTriggered: currentWebview.url = value
        },
        Actions.Back {
            enabled: currentWebview ? currentWebview.canGoBack : false
            onTriggered: currentWebview.goBack()
        },
        Actions.Forward {
            enabled: currentWebview ? currentWebview.canGoForward : false
            onTriggered: currentWebview.goForward()
        },
        Actions.Reload {
            enabled: currentWebview
            onTriggered: currentWebview.reload()
        },
        Actions.Bookmark {
            enabled: currentWebview
            onTriggered: _bookmarksModel.add(currentWebview.url, currentWebview.title, "")//currentWebview.icon)
        },
        Actions.NewTab {
            onTriggered: openUrlInNewTab("", true)
        },
        Actions.ClearHistory {
            onTriggered: _historyModel.clearAll()
        }
    ]

    Page {
        // Work around http://pad.lv/1305834 by forcing the page title to be
        // reset to an empty string when the activity view is being hidden.
        title: activityViewVisible ? " " : ""
        anchors.fill: parent
        visible: !activityViewVisible
        active: visible

        Item {
            id: webviewContainer
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height
        }

        ErrorSheet {
            anchors.fill: webviewContainer
            visible: currentWebview ? currentWebview.lastLoadFailed : false
            url: currentWebview ? currentWebview.url : ""
            onRefreshClicked: currentWebview.reload()
        }
    }

    PageStack {
        id: stack
        active: depth > 0
    }

    QtObject {
        id: internal

        function onHistoryEntryRequested(url) {
            currentWebview.url = url
            toggleActivityView()
        }

        function onNewTabRequested() {
            toggleActivityView()
            openUrlInNewTab("", true)
        }

        function onSwitchToTabRequested(index) {
            switchToTab(index)
            toggleActivityView()
        }

        function onCloseTabRequested(index) {
            closeTab(index)
            if (tabsModel.count === 0) {
                onNewTabRequested()
            }
        }

        function onBookmarkRequested(url) {
            currentWebview.url = url
            toggleActivityView()
        }

        function onNewTabUrlRequested(url) {
            currentWebview.url = url
            currentWebview.forceActiveFocus()
        }
    }

    readonly property bool activityViewVisible: stack.depth > 0

    function showActivityView() {
        stack.push(Qt.resolvedUrl("ActivityView.qml"),
                   {tabsModel: tabsModel,
                    historyModel: _historyModel,
                    bookmarksModel: _bookmarksModel})
        var view = stack.currentPage
        view.onHistoryEntryRequested.connect(internal.onHistoryEntryRequested)
        view.onNewTabRequested.connect(internal.onNewTabRequested)
        view.onSwitchToTabRequested.connect(internal.onSwitchToTabRequested)
        view.onCloseTabRequested.connect(internal.onCloseTabRequested)
        view.onBookmarkRequested.connect(internal.onBookmarkRequested)
        if (currentWebview) {
            currentWebview.forceActiveFocus()
        }
        panel.close()
    }

    function hideActivityView() {
        stack.pop()
    }

    function toggleActivityView() {
        if (activityViewVisible) {
            hideActivityView()
        } else {
            showActivityView()
        }
    }

    PanelLoader {
        id: panel

        currentWebview: browser.currentWebview
        chromeless: browser.chromeless
        searchUrl: browser.searchEngine ? browser.searchEngine.template : ""

        anchors {
            left: parent.left
            right: parent.right
            bottom: panel.opened ? osk.top : parent.bottom
        }

        onUrlValidated: {
            if (activityViewVisible) {
                hideActivityView()
            }
        }

        onToggleActivityViewClicked: toggleActivityView()
    }

    Suggestions {
        opacity: (panel.chrome && (panel.state == "spread") &&
                  panel.chrome.addressBar.activeFocus && (count > 0)) ? 1.0 : 0.0
        Behavior on opacity {
            UbuntuNumberAnimation {}
        }
        enabled: opacity > 0
        anchors {
            bottom: panel.top
            horizontalCenter: parent.horizontalCenter
        }
        width: panel.width - units.gu(5)
        height: Math.min(contentHeight, panel.y - units.gu(2))
        model: historyMatches
        onSelected: {
            currentWebview.url = url
            currentWebview.forceActiveFocus()
        }
    }

    HistoryModel {
        id: _historyModel
        databasePath: dataLocation + "/history.sqlite"
    }

    HistoryMatchesModel {
        id: historyMatches
        sourceModel: _historyModel
        query: panel.chrome ? panel.chrome.addressBar.text : ""
    }

    TabsModel {
        id: tabsModel
    }

    BookmarksModel {
        id: _bookmarksModel
        databasePath: dataLocation + "/bookmarks.sqlite"
    }

    Component {
        id: webviewComponent

        WebViewImpl {
            currentWebview: browser.currentWebview
            toolbar: panel.panel

            anchors.fill: parent

            readonly property bool current: currentWebview === this
            enabled: current
            visible: current

            //experimental.preferences.developerExtrasEnabled: developerExtrasEnabled
            preferences.localStorageEnabled: true
            preferences.appCacheEnabled: true

            contextualActions: ActionList {
                Actions.OpenLinkInNewTab {
                    enabled: contextualData.href.toString()
                    onTriggered: openUrlInNewTab(contextualData.href, true)
                }
                Actions.BookmarkLink {
                    enabled: contextualData.href.toString()
                    onTriggered: _bookmarksModel.add(contextualData.href, contextualData.title, "")
                }
                Actions.CopyLink {
                    enabled: contextualData.href.toString()
                    onTriggered: Clipboard.push([contextualData.href])
                }
                Actions.OpenImageInNewTab {
                    enabled: contextualData.img.toString()
                    onTriggered: openUrlInNewTab(contextualData.img, true)
                }
                Actions.CopyImage {
                    enabled: contextualData.img.toString()
                    onTriggered: Clipboard.push([contextualData.img])
                }
                Actions.SaveImage {
                    enabled: contextualData.img.toString() && downloadLoader.status == Loader.Ready
                    onTriggered: downloadLoader.item.downloadPicture(contextualData.img)
                }
            }

            onNewViewRequested: {
                var webview = webviewComponent.createObject(webviewContainer, {"request": request})
                addTab(webview, true, false)
            }

            onLoadingChanged: {
                if (lastLoadSucceeded) {
                    _historyModel.add(url, title, "")
                }
            }

            Loader {
                id: newTabViewLoader
                anchors.fill: parent

                sourceComponent: !parent.url.toString() ? newTabViewComponent : undefined

                Component {
                    id: newTabViewComponent

                    NewTabView {
                        anchors.fill: parent

                        historyModel: _historyModel
                        bookmarksModel: _bookmarksModel
                        onBookmarkClicked: internal.onNewTabUrlRequested(url)
                        onHistoryEntryClicked: internal.onNewTabUrlRequested(url)
                    }
                }
            }
        }
    }

    Loader {
        id: downloadLoader
        source: formFactor == "desktop" ? "" : "../Downloader.qml"
    }

    function addTab(webview, setCurrent, focusAddressBar) {
        var index = tabsModel.add(webview)
        if (setCurrent) {
            tabsModel.currentIndex = index
            if (!chromeless) {
                if (focusAddressBar) {
                    panel.chrome.addressBar.forceActiveFocus()
                    Qt.inputMethod.show() // work around http://pad.lv/1316057
                    panel.open()
                }
            }
        }
    }

    function openUrlInNewTab(url, setCurrent) {
        var webview = webviewComponent.createObject(webviewContainer, {"url": url})
        addTab(webview, setCurrent, !url.toString())
    }

    function closeTab(index) {
        var webview = tabsModel.remove(index)
        if (webview) {
            webview.destroy()
        }
    }

    function switchToTab(index) {
        tabsModel.currentIndex = index
        currentWebview.forceActiveFocus()
    }
}
