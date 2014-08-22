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
import com.canonical.Oxide 1.0 as Oxide
import Ubuntu.Components 1.1
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1
import "../actions" as Actions
import ".."

BrowserView {
    id: browser

    currentWebview: tabsModel.currentTab ? tabsModel.currentTab.webview : null

    property var historyModel: (historyModelLoader.status == Loader.Ready) ? historyModelLoader.item : null
    property var bookmarksModel: (bookmarksModelLoader.status == Loader.Ready) ? bookmarksModelLoader.item : null

    property url homepage
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
            enabled: currentWebview && browser.bookmarksModel
            onTriggered: browser.bookmarksModel.add(currentWebview.url, currentWebview.title, currentWebview.icon)
        },
        Actions.NewTab {
            onTriggered: browser.openUrlInNewTab("", true)
        },
        Actions.ClearHistory {
            enabled: browser.historyModel
            onTriggered: browser.historyModel.clearAll()
        }
    ]

    Item {
        id: previewsContainer

        width: tabContainer.width
        height: tabContainer.height
        y: tabContainer.y

        Component {
            id: previewComponent

            ShaderEffectSource {
                id: preview

                property var tab

                width: parent.width
                height: parent.height

                sourceItem: tab ? tab.webview : null

                onTabChanged: {
                    if (!tab) {
                        this.destroy()
                    }
                }

                live: mainView.visible && (browser.currentWebview === sourceItem)
            }
        }
    }

    Item {
        id: mainView

        anchors.fill: parent
        visible: !historyViewContainer.visible && !tabsViewContainer.visible

        Item {
            id: tabContainer
            anchors {
                left: parent.left
                right: parent.right
                top: chrome.bottom
            }
            height: parent.height - chrome.visibleHeight - osk.height
        }

        Loader {
            anchors.fill: tabContainer
            sourceComponent: ErrorSheet {
                visible: currentWebview ? currentWebview.lastLoadFailed : false
                url: currentWebview ? currentWebview.url : ""
                onRefreshClicked: currentWebview.reload()
            }
            asynchronous: true
        }

        Chrome {
            id: chrome

            webview: browser.currentWebview
            searchUrl: browser.searchEngine ? browser.searchEngine.template : ""

            function isCurrentUrlBookmarked() {
                return ((webview && browser.bookmarksModel) ? browser.bookmarksModel.contains(webview.url) : false)
            }
            bookmarked: isCurrentUrlBookmarked()
            onBookmarkedChanged: {
                if (bookmarked && !isCurrentUrlBookmarked()) {
                    browser.bookmarksModel.add(webview.url, webview.title, webview.icon)
                } else if (!bookmarked && isCurrentUrlBookmarked()) {
                    browser.bookmarksModel.remove(webview.url)
                }
            }
            onWebviewChanged: bookmarked = isCurrentUrlBookmarked()
            Connections {
                target: chrome.webview
                onUrlChanged: chrome.bookmarked = chrome.isCurrentUrlBookmarked()
            }
            Connections {
                target: browser.bookmarksModel
                onAdded: if (!chrome.bookmarked && (url === chrome.webview.url)) chrome.bookmarked = true
                onRemoved: if (chrome.bookmarked && (url === chrome.webview.url)) chrome.bookmarked = false
            }

            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(6)

            drawerActions: [
                Action {
                    objectName: "share"
                    text: i18n.tr("Share")
                    iconName: "share"
                    enabled: (formFactor == "mobile") && browser.currentWebview && browser.currentWebview.url.toString()
                    onTriggered: {
                        var component = Qt.createComponent("../Share.qml")
                        if (component.status == Component.Ready) {
                            var share = component.createObject(browser)
                            share.onDone.connect(share.destroy)
                            share.shareLink(browser.currentWebview.url, browser.currentWebview.title)
                        }
                    }
                },
                Action {
                    objectName: "history"
                    text: i18n.tr("History")
                    iconName: "history"
                    enabled: browser.historyModel
                    onTriggered: historyViewComponent.createObject(historyViewContainer)
                },
                Action {
                    objectName: "tabs"
                    text: i18n.tr("Open tabs")
                    iconName: "browser-tabs"
                    onTriggered: tabsViewComponent.createObject(tabsViewContainer)
                },
                Action {
                    objectName: "newtab"
                    text: i18n.tr("New tab")
                    iconName: "tab-new"
                    onTriggered: browser.openUrlInNewTab("", true)
                }
            ]

            Connections {
                target: browser.currentWebview
                onLoadingChanged: {
                    if (browser.currentWebview.loading) {
                        chrome.state = "shown"
                    } else if (browser.currentWebview.fullscreen) {
                        chrome.state = "hidden"
                    }
                }
                onFullscreenChanged: {
                    if (browser.currentWebview.fullscreen) {
                        chrome.state = "hidden"
                    } else {
                        chrome.state = "shown"
                    }
                }
            }
        }

        ChromeStateTracker {
            webview: browser.currentWebview
            header: chrome
        }

        Suggestions {
            opacity: ((chrome.state == "shown") && chrome.activeFocus && (count > 0) && !chrome.drawerOpen) ? 1.0 : 0.0
            Behavior on opacity {
                UbuntuNumberAnimation {}
            }
            enabled: opacity > 0
            anchors {
                top: chrome.bottom
                horizontalCenter: parent.horizontalCenter
            }
            width: chrome.width - units.gu(5)
            height: enabled ? Math.min(contentHeight, tabContainer.height - units.gu(2)) : 0
            model: HistoryMatchesModel {
                sourceModel: browser.historyModel
                query: chrome.text
            }
            onSelected: {
                browser.currentWebview.url = url
                browser.currentWebview.forceActiveFocus()
            }
        }
    }

    Item {
        id: tabsViewContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: tabsViewComponent

            TabsView {
                anchors.fill: parent
                model: tabsModel
                onNewTabRequested: browser.openUrlInNewTab("", true, false)
                onDone: {
                    tabsModel.currentTab.load()
                    this.destroy()
                }
            }
        }
    }

    Item {
        id: historyViewContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: historyViewComponent

            HistoryView {
                anchors.fill: parent
                visible: historyViewContainer.children.length == 1

                Timer {
                    // Set the model asynchronously to ensure
                    // the view is displayed as early as possible.
                    running: true
                    interval: 1
                    onTriggered: historyModel = browser.historyModel
                }

                onSeeMoreEntriesClicked: {
                    var view = expandedHistoryViewComponent.createObject(historyViewContainer, {model: model})
                    view.onHistoryEntryClicked.connect(destroy)
                }
                onHistoryDomainRemoved: browser.historyModel.removeEntriesByDomain(domain)
                onDone: destroy()
            }
        }

        Component {
            id: expandedHistoryViewComponent

            ExpandedHistoryView {
                anchors.fill: parent

                onHistoryEntryClicked: {
                    currentWebview.url = url
                    done()
                }
                onHistoryEntryRemoved: browser.historyModel.removeEntryByUrl(url)
                onDone: destroy()
            }
        }
    }

    TabsModel {
        id: tabsModel
    }

    Loader {
        id: historyModelLoader
        source: "HistoryModel.qml"
        asynchronous: true
    }

    Loader {
        id: bookmarksModelLoader
        source: "BookmarksModel.qml"
        asynchronous: true
    }

    Component {
        id: tabComponent

        FocusScope {
            property url initialUrl
            property string initialTitle
            property var request
            readonly property var webview: (children.length == 1) ? children[0] : null
            readonly property url url: webview ? webview.url : initialUrl
            readonly property string title: webview ? webview.title : initialTitle
            readonly property url icon: webview ? webview.icon : ""
            property var preview

            anchors.fill: parent

            function load() {
                if (!webview) {
                    webviewComponent.incubateObject(this, {"url": initialUrl})
                }
            }

            function unload() {
                if (webview) {
                    webview.destroy()
                }
            }

            Component.onCompleted: {
                if (request) {
                    // Instantiating the webview cannot be delayed because the request
                    // object is destroyed after exiting the newViewRequested signal handler.
                    webviewComponent.incubateObject(this, {"request": request})
                }
            }
        }
    }

    Component {
        id: webviewComponent

        WebViewImpl {
            currentWebview: browser.currentWebview

            anchors.fill: parent
            focus: true

            readonly property bool current: currentWebview === this
            enabled: current
            visible: current

            //experimental.preferences.developerExtrasEnabled: developerExtrasEnabled
            preferences.localStorageEnabled: true
            preferences.appCacheEnabled: true

            contextualActions: ActionList {
                Actions.OpenLinkInNewTab {
                    enabled: contextualData.href.toString()
                    onTriggered: browser.openUrlInNewTab(contextualData.href, true)
                }
                Actions.BookmarkLink {
                    enabled: contextualData.href.toString() && browser.bookmarksModel
                    onTriggered: browser.bookmarksModel.add(contextualData.href, contextualData.title, "")
                }
                Actions.CopyLink {
                    enabled: contextualData.href.toString()
                    onTriggered: Clipboard.push([contextualData.href])
                }
                Actions.OpenImageInNewTab {
                    enabled: contextualData.img.toString()
                    onTriggered: browser.openUrlInNewTab(contextualData.img, true)
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
                var tab = tabComponent.createObject(tabContainer, {"request": request})
                var setCurrent = (request.disposition == Oxide.NewViewRequest.DispositionNewForegroundTab)
                internal.addTab(tab, setCurrent, false)
            }

            onLoadingChanged: {
                if (lastLoadSucceeded && browser.historyModel) {
                    browser.historyModel.add(url, title, icon)
                }
            }

            onGeolocationPermissionRequested: requestGeolocationPermission(request)

            Loader {
                id: newTabViewLoader
                anchors.fill: parent

                sourceComponent: !parent.url.toString() ? newTabViewComponent : undefined

                Component {
                    id: newTabViewComponent

                    NewTabView {
                        anchors.fill: parent

                        historyModel: browser.historyModel
                        bookmarksModel: browser.bookmarksModel
                        onBookmarkClicked: {
                            currentWebview.url = url
                            currentWebview.forceActiveFocus()
                        }
                        onHistoryEntryClicked: {
                            currentWebview.url = url
                            currentWebview.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: downloadLoader
        source: formFactor == "desktop" ? "" : "../Downloader.qml"
        asynchronous: true
    }

    QtObject {
        id: internal

        function addTab(tab, setCurrent, focusAddressBar) {
            var index = tabsModel.add(tab)
            if (setCurrent) {
                tabsModel.setCurrent(index)
                if (focusAddressBar) {
                    internal.focusAddressBar()
                }
            }
            tab.preview = previewComponent.createObject(previewsContainer, {tab: tab})
        }

        function focusAddressBar() {
            chrome.forceActiveFocus()
            Qt.inputMethod.show() // work around http://pad.lv/1316057
        }
    }

    function openUrlInNewTab(url, setCurrent, load) {
        load = typeof load !== 'undefined' ? load : true
        var tab = tabComponent.createObject(tabContainer, {"initialUrl": url})
        internal.addTab(tab, setCurrent, !url.toString() && (formFactor == "desktop"))
        if (load) {
            tabsModel.currentTab.load()
        }
    }

    SessionStorage {
        id: session

        dataFile: dataLocation + "/session.json"

        function save() {
            if (!locked) {
                return
            }
            var tabs = []
            for (var i = 0; i < tabsModel.count; ++i) {
                var tab = tabsModel.get(i)
                tabs.push(serializeTabState(tab))
            }
            store(JSON.stringify({tabs: tabs}))
        }

        function restore() {
            if (!locked) {
                return
            }
            var state = null
            try {
                state = JSON.parse(retrieve())
            } catch (e) {
                return
            }
            if (state) {
                var tabs = state.tabs
                if (tabs) {
                    for (var i = 0; i < tabs.length; ++i) {
                        var tab = createTabFromState(tabs[i])
                        internal.addTab(tab, i == 0, false)
                    }
                }
            }
        }

        // Those two functions are used to save/restore the current state of a tab.
        // The current implementation is naive, it only saves/restores the current URL.
        // In the future, we’ll want to rely on oxide to save and restore a full state
        // of the corresponding webview as a binary blob, which includes navigation
        // history, current scroll offset and form data. See http://pad.lv/1353143.
        function serializeTabState(tab) {
            var state = {}
            state.url = tab.url.toString()
            state.title = tab.title
            return state
        }

        function createTabFromState(state) {
            var properties = {"initialUrl": state.url, "initialTitle": state.title}
            return tabComponent.createObject(tabContainer, properties)
        }
    }
    Connections {
        target: tabsModel
        onCurrentTabChanged: session.save()
        onCountChanged: session.save()
    }
    Connections {
        target: browser.currentWebview
        onUrlChanged: session.save()
        onTitleChanged: session.save()
    }
    Component.onCompleted: {
        if (browser.restoreSession) {
            session.restore()
        }
        for (var i in browser.initialUrls) {
            browser.openUrlInNewTab(browser.initialUrls[i], true, false)
        }
        if (tabsModel.count == 0) {
            browser.openUrlInNewTab(browser.homepage, true, false)
        }
        tabsModel.currentTab.load()
        if (!tabsModel.currentTab.url.toString() && (formFactor == "desktop")) {
            internal.focusAddressBar()
        }
    }
}
