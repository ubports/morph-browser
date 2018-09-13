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

import QtQuick 2.5
import QtQuick.Window 2.2
import QtSystemInfo 5.5
import Qt.labs.settings 1.0
//import com.canonical.Oxide 1.19 as Oxide
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1
import "../actions" as Actions
import "../UrlUtils.js" as UrlUtils
import ".."
import "."
import "." as Local

BrowserView {
    id: browser

    property Settings settings

    currentWebview: tabsModel && tabsModel.currentTab ? tabsModel.currentTab.webview : null

    property bool incognito: false

    property var tabsModel: TabsModel {
        // These methods are required by the TabsBar component
        readonly property int selectedIndex: currentIndex

        function addTab() {
            internal.openUrlInNewTab("", true, true, count)
        }

        function addExistingTab(tab) {
            add(tab);

            browser.bindExistingTab(tab);
        }

        function moveTab(from, to) {
            if (from === to
                || from < 0 || from >= count
                || to < 0 || to >= count) {
                return;
            }

            move(from, to);
        }

        function removeTab(index) {
            internal.closeTab(index, false);
        }

        function removeTabWithoutDestroying(index) {
            internal.closeTab(index, true);
        }

        function selectTab(index) {
            internal.switchToTab(index, true);
        }
    }

    property BrowserWindow thisWindow
    property Component windowFactory

    function serializeTabState(tab) {
        var state = {}
        state.uniqueId = tab.uniqueId
        state.url = tab.url.toString()
        state.title = tab.title
        state.icon = tab.icon.toString()
        state.preview = tab.preview.toString()
        state.savedState = tab.webview ? tab.webview.currentState : tab.restoreState
        return state
    }

    function restoreTabState(state) {
        var properties = {'initialUrl': state.url, 'initialTitle': state.title,
                          'uniqueId': state.uniqueId, 'initialIcon': state.icon,
                          'preview': state.preview, 'restoreState': state.savedState}
                      //    'restoreType': Oxide.WebView.RestoreLastSessionExitedCleanly}
        return createTab(properties)
    }

    function createTab(properties) {
        return internal.createTabHelper(properties)
    }

    function bindExistingTab(tab) {
        Reparenter.reparent(tab, tabContainer);

        var properties = internal.buildContextProperties();

        for (var prop in properties) {
            tab[prop] = properties[prop];
        }

        // Ensure that we have switched to the tab
        // otherwise chrome position can break
        internal.switchToTab(tabsModel.count - 1, true);
    }

    signal newWindowRequested(bool incognito)
    signal newWindowFromTab(var tab, var callback)
    signal openLinkInWindowRequested(url url, bool incognito)
    signal openLinkInNewTabRequested(url url, bool background)
    signal shareLinkRequested(url linkUrl, string title)
    signal shareTextRequested(string text)
    signal fullScreenRequested(bool toggleOn)

    onShareLinkRequested: {

        internal.shareLink(linkUrl, title);
    }

    onShareTextRequested: {

        internal.shareText(text)
    }
    
    onFullScreenRequested: {
        
        if (toggleOn)
        {
            chrome.state = "hidden"
            browser.thisWindow.setFullscreen(true)
        }
        else
        {
            chrome.state = "shown"
            browser.thisWindow.setFullscreen(false)
        }
        
    }

    Connections {
        target: currentWebview

        /* Note that we are connecting the mediaAccessPermissionRequested signal
           on the current webview only because we want all the tabs that are not
           visible to automatically deny the request but emit the signal again
           if the same origin requests permissions (which is the default
           behavior in oxide if we don't connect a signal handler), so that we
           can pop-up a dialog asking the user for permission.

           Design is working on a new component that allows per-tab non-modal
           dialogs that will allow asking permission to the user without blocking
           interaction with the rest of the page or the window. When ready all
           tabs will have their mediaAccessPermissionRequested signal handled by
           creating one of these new dialogs.
        */
        //onMediaAccessPermissionRequested: PopupUtils.open(Qt.resolvedUrl("../MediaAccessDialog.qml"), null, { request: request })
    }

    //currentWebcontext: SharedWebContext.sharedContext
    defaultVideoCaptureDeviceId: settings.defaultVideoDevice ? settings.defaultVideoDevice : ""

    onDefaultVideoCaptureMediaIdUpdated: {
        if (!settings.defaultVideoDevice) {
            settings.defaultVideoDevice = defaultVideoCaptureDeviceId
        }
    }

    InputDeviceModel {
        id: miceModel
        filter: InputInfo.Mouse
    }

    InputDeviceModel {
        id: touchPadModel
        filter: InputInfo.TouchPad
    }

    InputDeviceModel {
        id: touchScreenModel
        filter: InputInfo.TouchScreen
    }

    FilteredKeyboardModel {
        id: keyboardModel
    }

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
            onTriggered: internal.addBookmark(currentWebview.url, currentWebview.title, currentWebview.icon)
        },
        Actions.NewTab {
            onTriggered: internal.openUrlInNewTab("", true)
        },
        Actions.ClearHistory {
            onTriggered: HistoryModel.clearAll()
        },
        Actions.FindInPage {
            enabled: !chrome.findInPageMode && !newTabViewLoader.active
            onTriggered: {
                chrome.findInPageMode = true
                chrome.focus = true
            }
        }
    ]

    FocusScope {
        id: contentsContainer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: chrome.bottom
        }
        visible: !settingsViewLoader.active && !historyViewLoader.active && !bookmarksViewLoader.active && !downloadsViewLoader.active

        FocusScope {
            id: tabContainer
            anchors {
                left: parent.left
                right: parent.right
                top: chrome.bottom
            }
            height: parent.height- osk.height - bottomEdgeBar.height
            // disable when newTabView is shown otherwise webview can capture drag events
            // do not use visible otherwise when a new tab is opened the locationBarController.offset
            // doesn't get updated, causing the Chrome to disappear
            enabled: !newTabViewLoader.active

            focus: !errorSheetLoader.focus &&
                   !invalidCertificateErrorSheetLoader.focus &&
                   !newTabViewLoader.focus &&
                   !sadTabLoader.focus

            Keys.onPressed: {
                if (tabContainer.visible && (event.key === Qt.Key_Backspace)) {
                    // Not handled as a window-level shortcut as it would take
                    // precedence over backspace events in HTML text fields
                    // (https://launchpad.net/bugs/1569938).
                    if (event.modifiers === Qt.NoModifier) {
                        internal.historyGoBack()
                        event.accepted = true
                    } else if (event.modifiers === Qt.ShiftModifier) {
                        internal.historyGoForward()
                        event.accepted = true
                    }
                }
            }
        }

        Loader {
            id: errorSheetLoader
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }
            Component.onCompleted: setSource("../ErrorSheet.qml", {
                                                 "visible": Qt.binding(function(){ return currentWebview ? (currentWebview.LoadStatus === WebEngineView.LoadFailedStatus) : false }),
                                                 "url": Qt.binding(function(){ return currentWebview ? currentWebview.url : "" })
                                             })
            Connections {
                target: errorSheetLoader.item
                onRefreshClicked: currentWebview.reload()
            }

            focus: item && item.visible
            asynchronous: true
        }

        Loader {
            id: invalidCertificateErrorSheetLoader
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }
            Component.onCompleted: setSource("../InvalidCertificateErrorSheet.qml", {
                                                 "visible": Qt.binding(function(){ return currentWebview && currentWebview.certificateError != null }),
                                                 "certificateError": Qt.binding(function(){ return currentWebview ? currentWebview.certificateError : null })
                                             })
            Connections {
                target: invalidCertificateErrorSheetLoader.item
                onAllowed: {
                    // Automatically allow future requests involving this
                    // certificate for the duration of the session.
                    internal.allowCertificateError(currentWebview.certificateError)
                    currentWebview.resetCertificateError()
                }
                onDenied: {
                    currentWebview.resetCertificateError()
                }
            }
            focus: item && item.visible
            asynchronous: true
        }

        Loader {
            id: newTabViewLoader

            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }
            clip: true  // prevents component from overlapping bottom edge etc

            // Avoid loading the new tab view if the webview has or will have content
            Connections {
                target: tabsModel.currentTab
                onEmptyChanged: newTabViewLoader.setActive(tabsModel.currentTab.empty)
            }
            Connections {
                target: tabsModel
                onCurrentTabChanged: newTabViewLoader.setActive(tabsModel.currentTab && tabsModel.currentTab.empty)
            }
            active: false
            focus: active
            asynchronous: true

            Connections {
                target: browser
                onWideChanged: newTabViewLoader.selectTabView()
            }
            Component.onCompleted: newTabViewLoader.selectTabView()

            // XXX: this is a workaround for bug #1659435 caused by QTBUG-54657.
            // New tab view was sometimes overlaid on top of other tabs because
            // it was not unloaded even though active was set to false.
            // Ref.: https://launchpad.net/bugs/1659435
            //       https://bugreports.qt.io/browse/QTBUG-54657
            function setActive(active) {
                if (active) {
                    if (newTabViewLoader.source == "") {
                        selectTabView();
                    }
                } else {
                    newTabViewLoader.setSource("", {});
                }
                newTabViewLoader.active = active;
            }

            function selectTabView() {
                var source = browser.incognito ? "NewPrivateTabView.qml" :
                                                 (browser.wide ? "NewTabViewWide.qml" :
                                                                 "NewTabView.qml");
                var properties = browser.incognito ? {} : {"settingsObject": settings,
                                                           "focus": true};

                newTabViewLoader.setSource(source, properties);
            }

            Connections {
                target: newTabViewLoader.item && !browser.incognito ? newTabViewLoader.item : null
                onBookmarkClicked: {
                    chrome.requestedUrl = url
                    currentWebview.url = url
                    tabContainer.forceActiveFocus()
                }
                onBookmarkRemoved: BookmarksModel.remove(url)
                onHistoryEntryClicked: {
                    chrome.requestedUrl = url
                    currentWebview.url = url
                    tabContainer.forceActiveFocus()
                }
            }
            Keys.onUpPressed: chrome.focus = true
        }

        Loader {
            id: sadTabLoader
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }

            active: webProcessMonitor.crashed || (webProcessMonitor.killed && !currentWebview.loading)
            focus: active

            Component.onCompleted: setSource("SadTab.qml", {
                                                 "webview": Qt.binding(function () {return browser.currentWebview})
                                             })
            Connections {
                target: sadTabLoader.item
                onCloseTabRequested: internal.closeCurrentTab()
            }

            WebProcessMonitor {
                id: webProcessMonitor
                webview: currentWebview
            }

            asynchronous: true
        }

        HoveredUrlLabel {
            anchors {
                left: tabContainer.left
                leftMargin: units.dp(-1)
                bottom: tabContainer.bottom
                bottomMargin: units.dp(-1)
            }
            height: units.gu(3)
            collapsedWidth: Math.min(units.gu(40), tabContainer.width)
            webview: browser.currentWebview
        }
    }

    FocusScope {
        id: recentView
        objectName: "recentView"

        anchors.fill: parent
        visible: bottomEdgeHandle.dragging || tabslist.animating || (state == "shown")
        onVisibleChanged: chrome.hidden = visible

        states: State {
            name: "shown"
        }

        function closeAndSwitchToTab(index) {
            recentView.reset()
            internal.switchToTab(index, false)
        }

        Keys.onEscapePressed: closeAndSwitchToTab(0)

        TabsList {
            id: tabslist
            anchors.fill: parent
            model: tabsModel
            readonly property real delegateMinHeight: units.gu(20)
            delegateHeight: {
                if (recentView.state == "shown") {
                    return Math.max(height / 3, delegateMinHeight)
                } else if (bottomEdgeHandle.stage == 0) {
                    return height
                } else if (bottomEdgeHandle.stage == 1) {
                    return (1 - 1.8 * bottomEdgeHandle.dragFraction) * height
                } else if (bottomEdgeHandle.stage >= 2) {
                    return Math.max(height / 3, delegateMinHeight)
                } else {
                    return delegateMinHeight
                }
            }
            chromeHeight: chrome.height
            onScheduleTabSwitch: {
                chrome.hidden = false
                internal.nextTabIndex = index
            }
            onTabSelected: recentView.closeAndSwitchToTab(index)
            onTabClosed: internal.closeTab(index)
        }

        Local.Toolbar {
            id: recentToolbar
            objectName: "recentToolbar"

            anchors {
                left: parent.left
                right: parent.right
            }
            height: units.gu(7)
            state: "hidden"

            color: browser.incognito ? UbuntuColors.darkGrey : "#f6f6f6"

            Button {
                objectName: "doneButton"
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }

                strokeColor: browser.incognito? "#f6f6f6" : UbuntuColors.darkGrey

                text: i18n.tr("Done")

                onClicked: recentView.closeAndSwitchToTab(0)
            }

            ToolbarAction {
                objectName: "newTabButton"
                anchors {
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                height: parent.height - units.gu(2)

                text: i18n.tr("New Tab")

                iconName: browser.incognito ? "private-tab-new" : "add"
                color: browser.incognito ? "#f6f6f6" : "#808080"

                onClicked: {
                    recentView.reset()
                    internal.openUrlInNewTab("", true)
                }
            }
        }

        function reset() {
            state = ""
            recentToolbar.state = "hidden"
            tabslist.reset()
            internal.resetFocus()
        }
    }

    SearchEngine {
        id: currentSearchEngine
        searchPaths: searchEnginesSearchPaths
        filename: settings.searchEngine
    }

    Chrome {
        id: chrome

        tab: internal.nextTab || tabsModel.currentTab
        tabsModel: browser.tabsModel
        searchUrl: currentSearchEngine.urlTemplate

        incognito: browser.incognito

        showTabsBar: browser.wide
        showFaviconInAddressBar: !browser.wide

        thisWindow: browser.thisWindow
        windowFactory: browser.windowFactory

        availableHeight: tabContainer.height - height - y

        touchEnabled: internal.hasTouchScreen

        tabsBarDimmed: dropAreaTopCover.containsDrag || dropAreaBottomCover.containsDrag

        property bool hidden: false

        Behavior on y {
            enabled: recentView.visible
            NumberAnimation {
                duration: UbuntuAnimation.FastDuration
            }
        }

        function isCurrentUrlBookmarked() {
            return tab ? BookmarksModel.contains(tab.url) : false
        }
        bookmarked: isCurrentUrlBookmarked()
        onToggleBookmark: {
            if (isCurrentUrlBookmarked()) BookmarksModel.remove(tab.url)
            else internal.addBookmark(tab.url, tab.title, tab.icon)
        }
        onWebviewChanged: bookmarked = isCurrentUrlBookmarked()
        Connections {
            target: chrome.tab
            onUrlChanged: chrome.bookmarked = chrome.isCurrentUrlBookmarked()
        }
        Connections {
            target: BookmarksModel
            onCountChanged: chrome.bookmarked = chrome.isCurrentUrlBookmarked()
        }

        onSwitchToTab: internal.switchToTab(index, true)
        onRequestNewTab: internal.openUrlInNewTab("", makeCurrent, true, index)
        onTabClosed: internal.closeTab(index, moving)

        onFindInPageModeChanged: {
            if (!chrome.findInPageMode) internal.resetFocus()
            else chrome.forceActiveFocus()
        }

        anchors {
            left: parent.left
            right: parent.right
        }

        drawerActions: [
            Action {
                objectName: "newwindow"
                text: i18n.tr("New window")
                iconName: "browser-tabs"
                onTriggered: browser.newWindowRequested(false)
            },
            Action {
                objectName: "newprivatewindow"
                text: i18n.tr("New private window")
                iconName: "private-browsing"
                onTriggered: browser.newWindowRequested(true)
            },
            Action {
                objectName: "share"
                text: i18n.tr("Share")
                iconName: "share"
                enabled: (contentHandlerLoader.status == Loader.Ready) &&
                         chrome.tab && chrome.tab.url.toString()
                onTriggered: internal.shareLink(chrome.tab.url, chrome.tab.title)
            },
            Action {
                objectName: "bookmarks"
                text: i18n.tr("Bookmarks")
                iconName: "bookmark"
                onTriggered: bookmarksViewLoader.active = true
            },
            Action {
                objectName: "history"
                text: i18n.tr("History")
                iconName: "history"
                onTriggered: historyViewLoader.active = true
            },
            Action {
                objectName: "findinpage"
                text: i18n.tr("Find in page")
                iconName: "search"
                enabled: !chrome.findInPageMode && !newTabViewLoader.active
                onTriggered: chrome.findInPageMode = true
            },
            Action {
                objectName: "downloads"
                text: i18n.tr("Downloads")
                iconName: "save"
                enabled: downloadHandlerLoader.status == Loader.Ready && contentHandlerLoader.status == Loader.Ready
                onTriggered: downloadsViewLoader.active = true
            },
            Action {
                objectName: "settings"
                text: i18n.tr("Settings")
                iconName: "settings"
                onTriggered: settingsViewLoader.active = true
            }
        ]

        canSimplifyText: !browser.wide
        editing: activeFocus || suggestionsList.activeFocus

        Keys.onDownPressed: {
            if (suggestionsList.count) suggestionsList.focus = true
            else if (!incognito && (newTabViewLoader.status == Loader.Ready)) {
                newTabViewLoader.forceActiveFocus()
            }
        }

        Keys.onEscapePressed: {
            if (chrome.findInPageMode) {
                chrome.findInPageMode = false
            } else {
                internal.resetFocus()
            }
        }

        Connections {
            target: browser.currentWebview
            onLoadingChanged: {
                if (browser.currentWebview.loading) {
                    chrome.state = "shown"
                } else if (browser.currentWebview.isFullScreen) {
                    chrome.state = "hidden"
                }
            }
            onFullscreenChanged: {
                if (browser.currentWebview.isFullScreen) {
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
        id: suggestionsList
        opacity: ((chrome.state == "shown") && (activeFocus || chrome.activeFocus) &&
                  (count > 0) && !chrome.drawerOpen && !chrome.findInPageMode) ? 1.0 : 0.0
        Behavior on opacity {
            UbuntuNumberAnimation {}
        }
        enabled: opacity > 0
        anchors {
            top: chrome.bottom
            horizontalCenter: parent.horizontalCenter
        }
        width: chrome.width - units.gu(5)
        height: enabled ? Math.min(contentHeight, tabContainer.height - chrome.height - units.gu(2)) : 0

        searchTerms: chrome.text.split(/\s+/g).filter(function(term) { return term.length > 0 })

        Keys.onUpPressed: chrome.focus = true
        Keys.onEscapePressed: internal.resetFocus()

        models: searchTerms && searchTerms.length > 0 ?
                [historySuggestions,
                 bookmarksSuggestions,
                 searchSuggestions.limit(4)] : []

        LimitProxyModel {
            id: historySuggestions
            limit: 2
            readonly property string icon: "history"
            readonly property bool displayUrl: true
            sourceModel: TextSearchFilterModel {
                sourceModel: HistoryModel
                terms: suggestionsList.searchTerms
                searchFields: ["url", "title"]
            }
        }

        LimitProxyModel {
            id: bookmarksSuggestions
            limit: 2
            readonly property string icon: "non-starred"
            readonly property bool displayUrl: true
            sourceModel: TextSearchFilterModel {
                sourceModel: BookmarksModel
                terms: suggestionsList.searchTerms
                searchFields: ["url", "title"]
            }
        }

        SearchSuggestions {
            id: searchSuggestions
            terms: suggestionsList.searchTerms
            searchEngine: currentSearchEngine
            active: (chrome.activeFocus || suggestionsList.activeFocus) &&
                     !browser.incognito && !chrome.findInPageMode &&
                     !UrlUtils.looksLikeAUrl(chrome.text.replace(/ /g, "+"))

            function limit(number) {
                var slice = results.slice(0, number)
                slice.icon = 'search'
                slice.displayUrl = false
                return slice
            }
        }

        onActivated: {
            browser.currentWebview.url = url
            tabContainer.forceActiveFocus()
            chrome.requestedUrl = url
        }
    }

    onWideChanged: {
        if (wide) {
            recentView.reset()
        } else {
            // In narrow mode, the tabslist is a stack: the current tab is always at the top.
            tabsModel.move(tabsModel.currentIndex, 0)
        }
    }

    BottomEdgeHandle {
        id: bottomEdgeHandle
        objectName: "bottomEdgeHandle"

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(2)

        enabled: !browser.wide && (recentView.state == "") &&
                 browser.currentWebview &&
                 (Screen.orientation == Screen.primaryOrientation)

        onDraggingChanged: {
            if (dragging) {
                if (browser.thisWindow) {
                    browser.thisWindow.setFullscreen(false)
                }
            } else {
                if (stage == 1) {
                    if (tabsModel.count > 1) {
                        tabslist.selectAndAnimateTab(1)
                    } else {
                        recentView.state = "shown"
                        recentToolbar.state = "shown"
                    }
                } else if (stage == 2) {
                    recentView.state = "shown"
                    recentToolbar.state = "shown"
                } else if (stage >= 3) {
                    recentView.state = "shown"
                    recentToolbar.state = "shown"
                }
            }
        }
    }

    Image {
        id: bottomEdgeHint
        source: "assets/bottom_edge_hint.png"
        property bool forceShow: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: (((chrome.state == "shown") && browser.currentWebview && !browser.currentWebview.fullscreen) || forceShow) ? 0 : -height
            Behavior on bottomMargin {
                UbuntuNumberAnimation {}
            }
        }
        visible: bottomEdgeHandle.enabled && !internal.hasMouse
        opacity: recentView.visible ? 0 : 1
        asynchronous: true
        Behavior on opacity {
            UbuntuNumberAnimation {}
        }

        Label {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: units.dp(2)
            }

            fontSize: "small"
            // TRANSLATORS: %1 refers to the current number of tabs opened
            text: i18n.tr("(%1)").arg(tabsModel ? tabsModel.count : 0)
        }
    }

    MouseArea {
        id: bottomEdgeBar
        objectName: "bottomEdgeBar"
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        enabled: !browser.wide && internal.hasMouse &&
                 (osk.state == "hidden") && (recentView.state == "")
        visible: enabled
        height: visible ? units.gu(4) : 0
        // Ensure that this ends up below the chrome, so that the
        // drawer menu’s inverse mouse area covers it.
        z: -1

        onClicked: {
            recentView.state = "shown"
            recentToolbar.state = "shown"
        }

        Rectangle {
            anchors.fill: parent
            color: "#f7f7f7"
            border {
                width: units.dp(1)
                color: "#cdcdcd"
            }
        }

        Label {
            anchors.centerIn: parent
            color: "#5d5d5d"
            // TRANSLATORS: %1 refers to the current number of tabs opened
            text: i18n.tr("(%1)").arg(tabsModel ? tabsModel.count : 0)
        }
    }

    Loader {
        id: bookmarksViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Connections {
            target: browser
            onWideChanged: bookmarksViewLoader.selectBookmarksView()
        }
        Component.onCompleted: bookmarksViewLoader.selectBookmarksView()

        function selectBookmarksView() {
            bookmarksViewLoader.setSource(browser.wide ? "BookmarksViewWide.qml" : "BookmarksView.qml",
                                          {"focus": true,
                                           "homepageUrl": Qt.binding(function () {return settings.homepage})
            });
        }

        onStatusChanged: {
            if (status == Loader.Ready) {
                chrome.findInPageMode = false
                forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }

        Connections {
            target: bookmarksViewLoader.item

            onBookmarkEntryClicked: {
                internal.openUrlInNewTab(url, true)
                bookmarksViewLoader.active = false
            }
            onBack: bookmarksViewLoader.active = false
            onNewTabClicked: {
                internal.openUrlInNewTab("", true)
                bookmarksViewLoader.active = false
            }
        }
    }

    Loader {
        id: historyViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Connections {
            target: browser
            onWideChanged: historyViewLoader.selectHistoryView()
        }
        Component.onCompleted: historyViewLoader.selectHistoryView()

        function selectHistoryView() {
            historyViewLoader.setSource(browser.wide ? "HistoryViewWide.qml" : "HistoryViewWithExpansion.qml",
                                        {"focus": true});
        }

        Connections {
            target: historyViewLoader.item
            onHistoryEntryClicked: {
                historyViewLoader.active = false
                internal.openUrlInNewTab(url, true)
            }
            onNewTabRequested: {
                historyViewLoader.active = false
                internal.openUrlInNewTab("", true)
            }
            onDone: {
                historyViewLoader.active = false
                internal.resetFocus()
            }
            onBack: historyViewLoader.active = false
        }

        onStatusChanged: {
            if (status == Loader.Ready) {
                chrome.findInPageMode = false
                forceActiveFocus()
                historyViewLoader.item.loadModel()
            } else {
                internal.resetFocus()
            }
        }
    }

    Loader {
        id: settingsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true

        onStatusChanged: {
            if (status == Loader.Ready) {
                chrome.findInPageMode = false
                forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }

        Component.onCompleted: setSource("SettingsPage.qml", {
                                             "focus": true,
                                             "settingsObject": settings
                                         })
        Connections {
            target: settingsViewLoader.item
            onDone: settingsViewLoader.active = false
        }
    }

    Loader {
        id: downloadsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("DownloadsPage.qml", {
                          "downloadManager": Qt.binding(function () {return downloadHandlerLoader.item}),
                          "incognito": incognito,
                          "focus": true
            })
        }

        Connections {
            target: downloadsViewLoader.item
            onDone: downloadsViewLoader.active = false
        }

        onStatusChanged: {
            if (status == Loader.Ready) {
                forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }
    }

    Loader {
        id: downloadHandlerLoader
        source: "DownloadHandler.qml"
        asynchronous: true
    }

    property Component tabComponent
    Loader {
        source: "TabComponent.qml"
        onLoaded: tabComponent = item
    }

    QtObject {
        id: internal
        property var closedTabHistory: []

        property int nextTabIndex: -1
        readonly property var nextTab: (nextTabIndex > -1) ? tabsModel.get(nextTabIndex) : null
        onNextTabChanged: {
            if (nextTab) {
                nextTab.aboutToShow()
            }
        }

        readonly property bool hasMouse: (miceModel.count + touchPadModel.count) > 0
        readonly property bool hasTouchScreen: touchScreenModel.count > 0

        // Ref: https://code.google.com/p/chromium/codesearch#chromium/src/components/ui/zoom/page_zoom_constants.cc
        readonly property var zoomFactors: [0.25, 0.333, 0.5, 0.666, 0.75, 0.9, 1.0,
                                            1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 5.0]
        function changeZoomFactor(offset) {
            for (var i = 0; i < zoomFactors.length; ++i) {
                if (Math.abs(zoomFactors[i] - currentWebview.zoomFactor) <= 0.001) {
                    currentWebview.zoomFactor = zoomFactors[i + offset]
                    return
                }
            }
        }

        function instantiateShareComponent() {
            var component = Qt.createComponent("../Share.qml")
            if (component.status === Component.Ready) {
                var share = component.createObject(browser)
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

        function openUrlInNewTab(url, setCurrent, load, index) {
            load = typeof load !== 'undefined' ? load : true
            var tab = internal.createTabHelper({"initialUrl": url})
            addTab(tab, setCurrent, index)
            if (load) {
                tab.load()
            }
            if (!url.toString()) {
                maybeFocusAddressBar()
            }
        }

        function addTab(tab, setCurrent, index) {
            if (index === undefined) index = tabsModel.add(tab)
            else index = tabsModel.insert(tab, index)
            if (setCurrent) {
                chrome.requestedUrl = tab.initialUrl
                switchToTab(index, true)
            }
        }

        function buildContextProperties(properties) {
            if (properties === undefined) {
                properties = {};
            }

            properties["bottomEdgeHandle"] = bottomEdgeHandle;
            properties["browser"] = browser;
            properties["chrome"] = chrome;
            properties["contentHandlerLoader"] = contentHandlerLoader;
            properties["downloadDialogLoader"] = downloadDialogLoader;
            properties["downloadsViewLoader"] = downloadsViewLoader;
            //properties["filePickerLoader"] = filePickerLoader;
            properties["internal"] = internal;
            properties["recentView"] = recentView;
            properties["tabsModel"] = tabsModel;

            return properties;
        }

        function createTabHelper(properties) {
            return Reparenter.createObject(tabComponent, tabContainer, internal.buildContextProperties(properties));
        }

        function closeTab(index, moving) {
            moving = moving === undefined ? false : moving;

            var tab = tabsModel.get(index)
            tabsModel.remove(index)

            if (tab) {
                if (!incognito && tab.url.toString().length > 0) {
                    closedTabHistory.push({
                        state: serializeTabState(tab),
                        index: index
                    })
                }

                // When moving a tab between windows don't close the tab as it has been moved
                if (!moving) {
                    tab.close()
                }
            }
            if (tabsModel.currentTab) {
                tabsModel.currentTab.load()
            }
            if (tabsModel.count === 0) {
                internal.openUrlInNewTab("", true)
                recentView.reset()
            }
        }

        function closeCurrentTab() {
            if (tabsModel.count > 0) {
                closeTab(tabsModel.currentIndex)
            }
        }

        function undoCloseTab() {
            if (!incognito && closedTabHistory.length > 0) {
                var tabInfo = closedTabHistory.pop()
                var tab = restoreTabState(tabInfo.state)
                addTab(tab, true, tabInfo.index)
                tab.load()
            }
        }

        function switchToPreviousTab() {
            if (browser.wide) {
                internal.switchToTab((tabsModel.currentIndex - 1 + tabsModel.count) % tabsModel.count, true)
            } else {
                internal.switchToTab(tabsModel.count - 1, true)
            }
        }

        function switchToNextTab() {
            if (browser.wide) {
                internal.switchToTab((tabsModel.currentIndex + 1) % tabsModel.count, true)
            } else {
                internal.switchToTab(tabsModel.count - 1, true)
            }
        }

        function switchToTab(index, delayed) {
            if (delayed) {
                nextTabIndex = index
                delayedTabSwitcher.restart()
            } else {
                tabsModel.currentIndex = index
                nextTabIndex = -1
                var tab = tabsModel.currentTab
                if (recentView.visible) {
                    recentView.focus = true
                } else if (tab) {
                    if (tab.empty) {
                        maybeFocusAddressBar()
                    } else {
                        tabContainer.forceActiveFocus()
                        tab.load();
                    }
                }
            }
        }

        function focusAddressBar(selectContent) {
            chrome.forceActiveFocus()
            Qt.inputMethod.show() // work around http://pad.lv/1316057
            if (selectContent) chrome.selectAll()
        }

        function resetFocus() {
            var currentTab = tabsModel.currentTab;
            if (currentTab) {
                if (currentTab.empty) {
                    internal.maybeFocusAddressBar()
                } else {
                    contentsContainer.focus = true;
                }
            }
        }

        function maybeFocusAddressBar() {
            if (keyboardModel.count > 0) {
                focusAddressBar()
            } else {
                contentsContainer.forceActiveFocus()
            }
        }

        // Invalid certificates the user has explicitly allowed for this session
        property var allowedCertificateErrors: []

        function allowCertificateError(error) {
            var host = UrlUtils.extractHost(error.url)
            var code = error.certError
            var fingerprint = error.certificate.fingerprintSHA1
            allowedCertificateErrors.push([host, code, fingerprint])
        }

        function isCertificateErrorAllowed(error) {
            var host = UrlUtils.extractHost(error.url)
            var code = error.certError
            var fingerprint = error.certificate.fingerprintSHA1
            for (var i in allowedCertificateErrors) {
                var allowed = allowedCertificateErrors[i]
                if ((host === allowed[0]) &&
                    (code === allowed[1]) &&
                    (fingerprint === allowed[2])) {
                    return true
                }
            }
            return false
        }

        function historyGoBack() {
            if (currentWebview && currentWebview.canGoBack) {
                internal.resetFocus()
                currentWebview.goBack()
            }
        }

        function historyGoForward() {
            if (currentWebview && currentWebview.canGoForward) {
                internal.resetFocus()
                currentWebview.goForward()
            }
        }

        property var currentBookmarkOptionsDialog: null
        function addBookmark(url, title, icon, location) {
            if (title == "") title = UrlUtils.removeScheme(url)
            BookmarksModel.add(url, title, icon, "")
            if (location === undefined) location = chrome.bookmarkTogglePlaceHolder
            var properties = {"bookmarkUrl": url, "bookmarkTitle": title}
            internal.currentBookmarkOptionsDialog = PopupUtils.open(Qt.resolvedUrl("BookmarkOptions.qml"),
                                                           location, properties)
        }
    }

    // Work around https://launchpad.net/bugs/1502675 by delaying the switch to
    // the next tab for a fraction of a second to avoid a black flash.
    Timer {
        id: delayedTabSwitcher
        interval: 50
        onTriggered: internal.switchToTab(internal.nextTabIndex, false)
    }

    Connections {
        target: tabsModel
        onCurrentTabChanged: {
            chrome.findInPageMode = false
            internal.resetFocus()
        }
    }

    // TODO: internationalize non-standard key sequences?

    // Ctrl+Tab or Ctrl+PageDown: cycle through open tabs
    Shortcut {
        sequence: StandardKey.NextChild
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.switchToNextTab()
    }
    Shortcut {
        sequence: "Ctrl+PgDown"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.switchToNextTab()
    }

    // Ctrl+Shift+Tab or Ctrl+PageUp: cycle through open tabs in reverse order
    Shortcut {
        sequence: StandardKey.PreviousChild
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }
    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }
    Shortcut {
        sequence: "Ctrl+PgUp"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }

    // Ctrl+W or Ctrl+F4: Close the current tab
    Shortcut {
        sequence: StandardKey.Close
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.closeCurrentTab()
    }
    Shortcut {
        sequence: "Ctrl+F4"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.closeCurrentTab()
    }

    // Ctrl+Shift+W or Ctrl+Shift+T: Undo close tab
    Shortcut {
        sequence: "Ctrl+Shift+W"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.undoCloseTab()
    }
    Shortcut {
        sequence: "Ctrl+Shift+T"
        enabled: contentsContainer.visible || recentView.visible
        onActivated: internal.undoCloseTab()
    }

    // Ctrl+T: Open a new Tab
    Shortcut {
        sequence: StandardKey.AddTab
        enabled: contentsContainer.visible || recentView.visible ||
                 bookmarksViewLoader.active || historyViewLoader.active
        onActivated: {
            internal.openUrlInNewTab("", true)
            if (recentView.visible) recentView.reset()
            bookmarksViewLoader.active = false
            historyViewLoader.active = false
        }
    }

    // F6 or Ctrl+L or Alt+D: Select the content in the address bar
    Shortcut {
        sequence: "F6"
        enabled: contentsContainer.visible
        onActivated: internal.focusAddressBar(true)
    }
    Shortcut {
        sequence: "Ctrl+L"
        enabled: contentsContainer.visible
        onActivated: internal.focusAddressBar(true)
    }
    Shortcut {
        sequence: "Alt+D"
        enabled: contentsContainer.visible
        onActivated: internal.focusAddressBar(true)
    }

    // Ctrl+D: Toggle bookmarked state on current Tab
    Shortcut {
        sequence: "Ctrl+D"
        enabled: contentsContainer.visible && !newTabViewLoader.active
        onActivated: {
            if (internal.currentBookmarkOptionsDialog) {
                internal.currentBookmarkOptionsDialog.hide()
            } else if (currentWebview) {
                if (BookmarksModel.contains(currentWebview.url)) {
                    BookmarksModel.remove(currentWebview.url)
                } else {
                    internal.addBookmark(currentWebview.url, currentWebview.title, currentWebview.icon)
                }
            }
        }
    }

    // Ctrl+H: Show History
    Shortcut {
        sequence: "Ctrl+H"
        enabled: contentsContainer.visible
        onActivated: historyViewLoader.active = true
    }

    // Ctrl+Shift+O: Show Bookmarks
    Shortcut {
        sequence: "Ctrl+Shift+O"
        enabled: contentsContainer.visible
        onActivated: bookmarksViewLoader.active = true
    }

    // Alt+← or Backspace: Goes to the previous page in history
    Shortcut {
        sequence: StandardKey.Back
        enabled: contentsContainer.visible
        onActivated: internal.historyGoBack()
    }

    // Alt+→ or Shift+Backspace: Goes to the next page in history
    Shortcut {
        sequence: StandardKey.Forward
        enabled: contentsContainer.visible
        onActivated: internal.historyGoForward()
    }

    // F5 or Ctrl+R: Reload current Tab
    Shortcut {
        sequence: "Ctrl+R"
        enabled: contentsContainer.visible
        onActivated: if (currentWebview) currentWebview.reload()
    }
    Shortcut {
        sequence: "F5"
        enabled: contentsContainer.visible
        onActivated: if (currentWebview) currentWebview.reload()
    }

    // Ctrl+F: Find in Page
    Shortcut {
        sequence: StandardKey.Find
        enabled: contentsContainer.visible && !newTabViewLoader.active
        onActivated: chrome.findInPageMode = true
    }

    // Ctrl+J: Show downloads page
    Shortcut {
        sequence: "Ctrl+J"
        enabled: chrome.visible &&
                 downloadHandlerLoader.status == Loader.Ready &&
                 contentHandlerLoader.status == Loader.Ready &&
                 !downloadsViewLoader.active
        onActivated: downloadsViewLoader.active = true
    }

    // Ctrl+G: Find next
    Shortcut {
        sequence: StandardKey.FindNext
        enabled: currentWebview && chrome.findInPageMode
        onActivated: currentWebview.findController.next()
    }

    // Ctrl+Shift+G: Find previous
    Shortcut {
        sequence: StandardKey.FindPrevious
        enabled: currentWebview && chrome.findInPageMode
        onActivated: currentWebview.findController.previous()
    }

    // Ctrl+Plus: zoom in
    Shortcut {
        sequence: StandardKey.ZoomIn
        enabled: currentWebview &&
                 ((currentWebview.maximumZoomFactor - currentWebview.zoomFactor) > 0.001)
        onActivated: internal.changeZoomFactor(1)
    }
    // For improved compatibility with qwerty-based keyboard layouts, where "="
    // and "+" are on the same key (see https://launchpad.net/bugs/1624381):
    Shortcut {
        sequence: "Ctrl+="
        enabled: currentWebview &&
                 ((currentWebview.maximumZoomFactor - currentWebview.zoomFactor) > 0.001)
        onActivated: internal.changeZoomFactor(1)
    }

    // Ctrl+Minus: zoom out
    Shortcut {
        sequence: StandardKey.ZoomOut
        enabled: currentWebview &&
                 ((currentWebview.zoomFactor - currentWebview.minimumZoomFactor) > 0.001)
        onActivated: internal.changeZoomFactor(-1)
    }
    // For improved compatibility with qwerty-based keyboard layouts, where "-"
    // and "_" are on the same key (see https://launchpad.net/bugs/1624381):
    Shortcut {
        sequence: "Ctrl+_"
        enabled: currentWebview &&
                 ((currentWebview.zoomFactor - currentWebview.minimumZoomFactor) > 0.001)
        onActivated: internal.changeZoomFactor(-1)
    }

    // Ctrl+0: reset zoom factor to 1.0
    Shortcut {
        sequence: "Ctrl+0"
        enabled: currentWebview && (currentWebview.zoomFactor !== 1.0)
        onActivated: currentWebview.zoomFactor = 1.0
    }

    Loader {
        id: contentHandlerLoader
        source: "../ContentHandler.qml"
        asynchronous: true
    }

    Connections {
        target: contentHandlerLoader.item
        onExportFromDownloads: {
            if (downloadHandlerLoader.status == Loader.Ready) {
                downloadsViewLoader.active = true
                downloadsViewLoader.item.mimetypeFilter = mimetypeFilter
                downloadsViewLoader.item.activeTransfer = transfer
                downloadsViewLoader.item.multiSelect = multiSelect
                downloadsViewLoader.item.pickingMode = true
            }
        }
    }

    Loader {
        id: downloadDialogLoader
        source: "ContentDownloadDialog.qml"
        asynchronous: true
    }

    /*

    Loader {
        id: filePickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }

    */

    // Cover the webview (gaps around tabsbar) with DropArea so that webview doesn't steal events
    DropArea {
        id: dropAreaTopCover
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: units.gu(1)
        keys: ["webbrowser/tab-" + (incognito ? "incognito" : "public")]
        visible: chrome.showTabsBar

        onEntered: {
            window.raise()
            window.requestActivate()
        }
    }

    DropArea {
        id: dropAreaBottomCover
        anchors {
            fill: parent
            topMargin: chrome.tabsBarHeight
        }
        keys: ["webbrowser/tab-" + (incognito ? "incognito" : "public")]

        onEntered: {
            window.raise()
            window.requestActivate()
        }
    }
}
