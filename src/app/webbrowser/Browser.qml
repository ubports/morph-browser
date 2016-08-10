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
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Ubuntu.Web 0.2
import com.canonical.Oxide 1.15 as Oxide
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Unity.InputInfo 0.1
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1
import "../actions" as Actions
import "../UrlUtils.js" as UrlUtils
import ".."
import "."
import "." as Local

BrowserView {
    id: browser

    // Should be true when the containing window is fullscreen.
    property bool fullscreen: false

    property Settings settings

    currentWebview: tabsModel && tabsModel.currentTab ? tabsModel.currentTab.webview : null

    property bool incognito: false

    property var tabsModel: TabsModel {}

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
                          'preview': state.preview, 'restoreState': state.savedState,
                          'restoreType': Oxide.WebView.RestoreLastSessionExitedCleanly}
        return createTab(properties)
    }

    function createTab(properties) {
        return tabComponent.createObject(tabContainer, properties)
    }

    signal newWindowRequested(bool incognito, url url)

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
        onMediaAccessPermissionRequested: PopupUtils.open(mediaAccessDialogComponent, null, { request: request })
    }

    currentWebcontext: SharedWebContext.sharedContext
    defaultVideoCaptureDeviceId: settings.defaultVideoDevice ? settings.defaultVideoDevice : ""

    onDefaultVideoCaptureMediaIdUpdated: {
        if (!settings.defaultVideoDevice) {
            settings.defaultVideoDevice = defaultVideoCaptureDeviceId
        }
    }

    InputDeviceModel {
        id: miceModel
        deviceFilter: InputInfo.Mouse
    }

    InputDeviceModel {
        id: touchPadModel
        deviceFilter: InputInfo.TouchPad
    }

    InputDeviceModel {
        id: touchScreenModel
        deviceFilter: InputInfo.TouchScreen
    }

    FilteredKeyboardModel {
        id: keyboardModel
    }

    Component {
        id: mediaAccessDialogComponent
        MediaAccessDialog {}
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
        anchors.fill: parent
        visible: !settingsViewLoader.active && !historyViewLoader.active && !bookmarksViewLoader.active && !downloadsViewLoader.active

        FocusScope {
            id: tabContainer
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height - bottomEdgeBar.height

            focus: !errorSheetLoader.focus &&
                   !invalidCertificateErrorSheetLoader.focus &&
                   !newTabViewLoader.focus &&
                   !sadTabLoader.focus

            Keys.onPressed: {
                if (tabContainer.visible && (event.key == Qt.Key_Backspace)) {
                    // Not handled as a window-level shortcut as it would take
                    // precedence over backspace events in HTML text fields
                    // (https://launchpad.net/bugs/1569938).
                    if (event.modifiers == Qt.NoModifier) {
                        internal.historyGoBack()
                        event.accepted = true
                    } else if (event.modifiers == Qt.ShiftModifier) {
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
            sourceComponent: ErrorSheet {
                visible: currentWebview ? currentWebview.lastLoadFailed : false
                url: currentWebview ? currentWebview.url : ""
                onRefreshClicked: currentWebview.reload()
            }
            focus: item.visible
            asynchronous: true
        }

        Loader {
            id: invalidCertificateErrorSheetLoader
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }
            sourceComponent: InvalidCertificateErrorSheet {
                visible: currentWebview && currentWebview.certificateError != null
                certificateError: currentWebview ? currentWebview.certificateError : null
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
            focus: item.visible
            asynchronous: true
        }

        Loader {
            id: newTabViewLoader

            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }

            // Avoid loading the new tab view if the webview is about to load
            // content. Since WebView.restoreState is not a notifyable property,
            // this can’t be achieved with a simple property binding.
            Connections {
                target: currentWebview
                onUrlChanged: {
                    newTabViewLoader.active = false
                }
            }
            active: false
            focus: active
            asynchronous: true

            Connections {
                target: browser
                onCurrentWebviewChanged: {
                    if (currentWebview) {
                        var tab = tabsModel.currentTab
                        newTabViewLoader.active = !tab.url.toString() && !tab.restoreState
                    }
                }
            }

            sourceComponent: browser.incognito ? newPrivateTabView :
                             (browser.wide ? newTabViewWide : newTabView)

            Component {
                id: newTabView

                NewTabView {
                    anchors.fill: parent
                    settingsObject: settings
                    focus: true
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
                    Keys.onUpPressed: chrome.focus = true
                }
            }

            Component {
                id: newTabViewWide

                NewTabViewWide {
                    anchors.fill: parent
                    settingsObject: settings
                    focus: true
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
                    Keys.onUpPressed: chrome.focus = true
                }
            }

            Component {
                id: newPrivateTabView

                NewPrivateTabView { anchors.fill: parent }
            }
        }

        Loader {
            id: sadTabLoader
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }

            active: webProcessMonitor.crashed || (webProcessMonitor.killed && !currentWebview.loading)
            focus: active

            sourceComponent: SadTab {
                webview: currentWebview
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

    ChromeController {
        id: chromeController
        webview: browser.currentWebview
        forceHide: browser.fullscreen
        forceShow: recentView.visible
        defaultMode: (internal.hasMouse && !internal.hasTouchScreen)
                         ? Oxide.LocationBarController.ModeShown
                         : Oxide.LocationBarController.ModeAuto
    }

    Chrome {
        id: chrome

        tab: internal.nextTab || tabsModel.currentTab
        webview: tab ? tab.webview : null
        tabsModel: browser.tabsModel
        searchUrl: currentSearchEngine.urlTemplate

        incognito: browser.incognito

        showTabsBar: browser.wide
        showFaviconInAddressBar: !browser.wide

        availableHeight: tabContainer.height - height - y

        touchEnabled: internal.hasTouchScreen

        property bool hidden: false
        y: hidden ? -height : webview ? webview.locationBarController.offset : 0
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
        onTabClosed: internal.closeTab(index)

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
                onTriggered: browser.newWindowRequested(false, null)
            },
            Action {
                objectName: "newprivatewindow"
                text: i18n.tr("New private window")
                iconName: "private-browsing"
                onTriggered: browser.newWindowRequested(true, null)
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
            /*Action {
                objectName: "privatemode"
                text: browser.incognito ? i18n.tr("Leave Private Mode") : i18n.tr("Private Mode")
                iconName: "private-browsing"
                iconSource: browser.incognito ? Qt.resolvedUrl("assets/private-browsing-exit.svg") : ""
                onTriggered: {
                    if (browser.incognito) {
                        if (tabsModel.count > 1) {
                            PopupUtils.open(leavePrivateModeDialog)
                        } else {
                            browser.incognito = false
                            internal.resetFocus()
                        }
                    } else {
                        browser.incognito = true
                    }
                }
            },*/
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
            else if (newTabViewLoader.status == Loader.Ready) {
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
                if (browser.currentWebview) {
                    browser.currentWebview.fullscreen = false
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
        sourceComponent: browser.wide ? bookmarksViewWideComponent : bookmarksViewComponent

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

        Component {
            id: bookmarksViewComponent

            BookmarksView {
                anchors.fill: parent
                focus: true
                homepageUrl: settings.homepage
            }
        }

        Component {
            id: bookmarksViewWideComponent

            BookmarksViewWide {
                anchors.fill: parent
                focus: true
                homepageUrl: settings.homepage
            }
        }
    }

    Loader {
        id: historyViewLoader

        anchors.fill: parent
        active: false
        sourceComponent: browser.wide ? historyViewWideComponent : historyViewComponent

        onStatusChanged: {
            if (status == Loader.Ready) {
                chrome.findInPageMode = false
                forceActiveFocus()
                historyViewLoader.item.loadModel()
            } else {
                internal.resetFocus()
            }
        }

        Component {
            id: historyViewComponent

            FocusScope {
                focus: true

                signal loadModel()
                onLoadModel: children[0].loadModel()

                HistoryView {
                    anchors.fill: parent
                    focus: !expandedHistoryViewLoader.focus
                    visible: focus
                    onSeeMoreEntriesClicked: {
                        expandedHistoryViewLoader.model = model
                        expandedHistoryViewLoader.active = true
                    }
                    onNewTabRequested: internal.openUrlInNewTab("", true)
                    onBack: historyViewLoader.active = false
                }

                Loader {
                    id: expandedHistoryViewLoader
                    asynchronous: true
                    anchors.fill: parent
                    active: false
                    focus: active
                    property var model: null
                    sourceComponent: ExpandedHistoryView {
                        focus: true
                        model: expandedHistoryViewLoader.model
                        onHistoryEntryClicked: {
                            internal.openUrlInNewTab(url, true)
                            historyViewLoader.active = false
                        }
                        onHistoryEntryRemoved: {
                            if (count == 1) {
                                done()
                            }
                            HistoryModel.removeEntryByUrl(url)
                        }
                        onDone: expandedHistoryViewLoader.active = false
                    }
                }
            }
        }

        Component {
            id: historyViewWideComponent

            HistoryViewWide {
                anchors.fill: parent
                focus: true

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
            }
        }
    }

    Loader {
        id: settingsViewLoader

        anchors.fill: parent
        active: false

        onStatusChanged: {
            if (status == Loader.Ready) {
                chrome.findInPageMode = false
                forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }

        sourceComponent: SettingsPage {
            anchors.fill: parent
            focus: true
            settingsObject: settings
            onDone: settingsViewLoader.active = false
        }
    }

    Loader {
        id: downloadsViewLoader

        anchors.fill: parent
        active: false
        source: "DownloadsPage.qml"

        Binding {
            target: downloadsViewLoader.item
            property: "downloadManager"
            value: downloadHandlerLoader.item
        }
        Binding {
            target: downloadsViewLoader.item
            property: "focus"
            value: true
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

    Component {
        id: tabComponent

        BrowserTab {
            anchors.fill: parent
            current: tabsModel && tabsModel.currentTab === this
            focus: current

            Item {
                id: contextualMenuTarget
                visible: false
            }

            webviewComponent: WebViewImpl {
                id: webviewimpl

                property BrowserTab tab
                readonly property bool current: tab.current

                currentWebview: browser.currentWebview
                filePicker: filePickerLoader.item

                anchors.fill: parent
                focus: true

                enabled: current && !bottomEdgeHandle.dragging && !recentView.visible

                locationBarController {
                    height: chrome.height
                    mode: chromeController.defaultMode
                }

                //experimental.preferences.developerExtrasEnabled: developerExtrasEnabled
                preferences.localStorageEnabled: true
                preferences.appCacheEnabled: true

                property QtObject contextModel: null
                contextualActions: ActionList {
                    Actions.OpenLinkInNewTab {
                        objectName: "OpenLinkInNewTabContextualAction"
                        enabled: contextModel && contextModel.linkUrl.toString()
                        onTriggered: internal.openUrlInNewTab(contextModel.linkUrl, true)
                    }
                    Actions.OpenLinkInNewBackgroundTab {
                        objectName: "OpenLinkInNewBackgroundTabContextualAction"
                        enabled: contextModel && contextModel.linkUrl.toString()
                        onTriggered: internal.openUrlInNewTab(contextModel.linkUrl, false)
                    }
                    Actions.OpenLinkInNewWindow {
                        objectName: "OpenLinkInNewWindowContextualAction"
                        enabled: contextModel && contextModel.linkUrl.toString()
                        onTriggered: browser.newWindowRequested(false, contextModel.linkUrl)
                    }
                    Actions.OpenLinkInNewPrivateWindow {
                        objectName: "OpenLinkInNewPrivateWindowContextualAction"
                        enabled: contextModel && contextModel.linkUrl.toString()
                        onTriggered: browser.newWindowRequested(true, contextModel.linkUrl)
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
                    Actions.OpenImageInNewTab {
                        objectName: "OpenImageInNewTabContextualAction"
                        enabled: contextModel &&
                                 (contextModel.mediaType === Oxide.WebView.MediaTypeImage) &&
                                 contextModel.srcUrl.toString()
                        onTriggered: internal.openUrlInNewTab(contextModel.srcUrl, true)
                    }
                    Actions.CopyImage {
                        objectName: "CopyImageContextualAction"
                        enabled: contextModel &&
                                 (contextModel.mediaType === Oxide.WebView.MediaTypeImage) &&
                                 contextModel.srcUrl.toString()
                        onTriggered: Clipboard.push(["text/plain", contextModel.srcUrl.toString()])
                    }
                    Actions.SaveImage {
                        objectName: "SaveImageContextualAction"
                        enabled: contextModel &&
                                 ((contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                                  (contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)) &&
                                 contextModel.hasImageContents
                        onTriggered: contextModel.saveMedia()
                    }
                    Actions.OpenVideoInNewTab {
                        objectName: "OpenVideoInNewTabContextualAction"
                        enabled: contextModel &&
                                 (contextModel.mediaType === Oxide.WebView.MediaTypeVideo) &&
                                 contextModel.srcUrl.toString()
                        onTriggered: internal.openUrlInNewTab(contextModel.srcUrl, true)
                    }
                    Actions.SaveVideo {
                        objectName: "SaveVideoContextualAction"
                        enabled: contextModel &&
                                 (contextModel.mediaType === Oxide.WebView.MediaTypeVideo) &&
                                 contextModel.srcUrl.toString()
                        onTriggered: contextModel.saveMedia()
                    }
                    Actions.Undo {
                        objectName: "UndoContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.UndoCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandUndo)
                    }
                    Actions.Redo {
                        objectName: "RedoContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.RedoCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandRedo)
                    }
                    Actions.Cut {
                        objectName: "CutContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.CutCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandCut)
                    }
                    Actions.Copy {
                        objectName: "CopyContextualAction"
                        enabled: contextModel && (contextModel.selectionText ||
                                 (contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.CopyCapability)))
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandCopy)
                    }
                    Actions.Paste {
                        objectName: "PasteContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.PasteCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandPaste)
                    }
                    Actions.Erase {
                        objectName: "EraseContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.EraseCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandErase)
                    }
                    Actions.SelectAll {
                        objectName: "SelectAllContextualAction"
                        enabled: contextModel && contextModel.isEditable &&
                                 (contextModel.editFlags & Oxide.WebView.SelectAllCapability)
                        onTriggered: webviewimpl.executeEditingCommand(Oxide.WebView.EditingCommandSelectAll)
                    }
                }

                function contextMenuOnCompleted(menu) {
                    contextModel = menu.contextModel
                    if (contextModel.linkUrl.toString() ||
                        contextModel.srcUrl.toString() ||
                        contextModel.selectionText ||
                        (contextModel.isEditable && contextModel.editFlags) ||
                        (((contextModel.mediaType == Oxide.WebView.MediaTypeImage) ||
                          (contextModel.mediaType == Oxide.WebView.MediaTypeCanvas)) &&
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
                contextMenu: browser.wide ? contextMenuWideComponent : contextMenuNarrowComponent

                onNewViewRequested: {
                    var tab = tabComponent.createObject(tabContainer, {"request": request, 'incognito': browser.incognito})
                    var setCurrent = (request.disposition == Oxide.NewViewRequest.DispositionNewForegroundTab)
                    internal.addTab(tab, setCurrent)
                    if (setCurrent) tabContainer.forceActiveFocus()
                }

                onCloseRequested: prepareToClose()
                onPrepareToCloseResponse: {
                    if (proceed) {
                        if (tab) {
                            for (var i = 0; i < tabsModel.count; ++i) {
                                if (tabsModel.get(i) === tab) {
                                    tabsModel.remove(i)
                                    break
                                }
                            }
                            tab.close()
                        }
                        if (tabsModel.count === 0) {
                            internal.openUrlInNewTab("", true, true)
                        }
                    }
                }

                QtObject {
                    id: webviewInternal
                    property url storedUrl: ""
                    property bool titleSet: false
                    property string title: ""
                }
                onLoadEvent: {
                    if (event.type == Oxide.LoadEvent.TypeCommitted) {
                        chrome.findInPageMode = false
                        webviewInternal.titleSet = false
                        webviewInternal.title = title
                    }

                    if (webviewimpl.incognito) {
                        return
                    }

                    if ((event.type == Oxide.LoadEvent.TypeCommitted) &&
                        !event.isError &&
                        (300 > event.httpStatusCode) && (event.httpStatusCode >= 200)) {
                        webviewInternal.storedUrl = event.url
                        HistoryModel.add(event.url, title, icon)
                    }
                }
                onTitleChanged: {
                    if (!webviewInternal.titleSet && webviewInternal.storedUrl.toString()) {
                        // Record the title to avoid updating the history database
                        // every time the page dynamically updates its title.
                        // We don’t want pages that update their title every second
                        // to achieve an ugly "scrolling title" effect to flood the
                        // history database with updates.
                        webviewInternal.titleSet = true
                        webviewInternal.title = title
                        HistoryModel.update(webviewInternal.storedUrl, title, icon)
                    }
                }
                onIconChanged: {
                    if (webviewInternal.storedUrl.toString()) {
                        HistoryModel.update(webviewInternal.storedUrl, webviewInternal.title, icon)
                    }
                }

                onGeolocationPermissionRequested: requestGeolocationPermission(request)

                property var certificateError
                function resetCertificateError() {
                    certificateError = null
                }
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

                onFullscreenChanged: {
                    if (fullscreen) {
                        fullscreenExitHintComponent.createObject(webviewimpl)
                    }
                }
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
                            onFullscreenChanged: {
                                if (!webviewimpl.fullscreen) {
                                    fullscreenExitHint.destroy()
                                }
                            }
                        }

                        Component.onCompleted: bottomEdgeHint.forceShow = true
                        Component.onDestruction: bottomEdgeHint.forceShow = false
                    }
                }

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

                function showDownloadsPage() {
                    downloadsViewLoader.active = true
                    return downloadsViewLoader.item
                }

                function startDownload(downloadId, download, mimeType) {
                    DownloadsModel.add(downloadId, download.url, mimeType)
                    download.start()
                    downloadsViewLoader.active = true
                }

            }
        }
    }

    Component {
        id: bookmarkOptionsComponent
        BookmarkOptions {
            folderModel: BookmarksFolderListModel {
                sourceModel: BookmarksModel
            }

            Component.onCompleted: forceActiveFocus()

            onVisibleChanged: {
                if (!visible) {
                    BookmarksModel.remove(bookmarkUrl)
                }
            }

            Component.onDestruction: {
                if (BookmarksModel.contains(bookmarkUrl)) {
                    BookmarksModel.update(bookmarkUrl, bookmarkTitle, bookmarkFolder)
                }
            }

            // Fragile workaround for https://launchpad.net/bugs/1546677.
            // By destroying the popover, its visibility isn’t changed to
            // false, and thus the bookmark is not removed.
            Keys.onEnterPressed: destroy()
            Keys.onReturnPressed: destroy()
        }
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
            if (component.status == Component.Ready) {
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
            var tab = tabComponent.createObject(tabContainer, {"initialUrl": url, 'incognito': browser.incognito})
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

        function closeTab(index) {
            var tab = tabsModel.remove(index)
            if (tab) {
                if (!incognito && tab.url.toString().length > 0) {
                    closedTabHistory.push({
                        state: serializeTabState(tab),
                        index: index
                    })
                }
                tab.close()
            }
            if (tabsModel.currentTab) {
                tabsModel.currentTab.load()
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
                    if (!tab.url.toString() && !tab.initialUrl.toString()) {
                        maybeFocusAddressBar()
                    } else {
                        tabContainer.forceActiveFocus()
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
            if (browser.currentWebview) {
                if (!browser.currentWebview.url.toString()) {
                    internal.maybeFocusAddressBar()
                } else {
                    contentsContainer.forceActiveFocus()
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
                if ((host == allowed[0]) &&
                    (code == allowed[1]) &&
                    (fingerprint == allowed[2])) {
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
            currentBookmarkOptionsDialog = PopupUtils.open(bookmarkOptionsComponent,
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

    Timer {
        running: true
        interval: 1
        onTriggered: {
            /*if (!delayedTabSwitcher.running) {
                tabsModel.currentTab.load()
            }*/
            if (!tabsModel.currentTab.url.toString() && !tabsModel.currentTab.restoreState) {
                internal.maybeFocusAddressBar()
            }
        }
    }

    Connections {
        target: tabsModel
        onCurrentIndexChanged: {
            // In narrow mode, the tabslist is a stack:
            // the current tab is always at the top.
            if (!browser.wide) {
                tabsModel.move(tabsModel.currentIndex, 0)
            }
        }
        onCurrentTabChanged: {
            chrome.findInPageMode = false
            /*var tab = tabsModel.currentTab
            if (tab) {
                tab.load()
            }*/
            internal.resetFocus()
        }
    }

    // TODO: internationalize non-standard key sequences?

    // Ctrl+Tab or Ctrl+PageDown: cycle through open tabs
    Shortcut {
        sequence: StandardKey.NextChild
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.switchToNextTab()
    }
    Shortcut {
        sequence: "Ctrl+PgDown"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.switchToNextTab()
    }

    // Ctrl+Shift+Tab or Ctrl+PageUp: cycle through open tabs in reverse order
    Shortcut {
        sequence: StandardKey.PreviousChild
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }
    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }
    Shortcut {
        sequence: "Ctrl+PgUp"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.switchToPreviousTab()
    }

    // Ctrl+W or Ctrl+F4: Close the current tab
    Shortcut {
        sequence: StandardKey.Close
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.closeCurrentTab()
    }
    Shortcut {
        sequence: "Ctrl+F4"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.closeCurrentTab()
    }

    // Ctrl+Shift+W or Ctrl+Shift+T: Undo close tab
    Shortcut {
        sequence: "Ctrl+Shift+W"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.undoCloseTab()
    }
    Shortcut {
        sequence: "Ctrl+Shift+T"
        enabled: tabContainer.visible || recentView.visible
        onActivated: internal.undoCloseTab()
    }

    // Ctrl+T: Open a new Tab
    Shortcut {
        sequence: StandardKey.AddTab
        enabled: tabContainer.visible || recentView.visible ||
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
        enabled: tabContainer.visible
        onActivated: internal.focusAddressBar(true)
    }
    Shortcut {
        sequence: "Ctrl+L"
        enabled: tabContainer.visible
        onActivated: internal.focusAddressBar(true)
    }
    Shortcut {
        sequence: "Alt+D"
        enabled: tabContainer.visible
        onActivated: internal.focusAddressBar(true)
    }

    // Ctrl+D: Toggle bookmarked state on current Tab
    Shortcut {
        sequence: "Ctrl+D"
        enabled: tabContainer.visible
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
        enabled: tabContainer.visible
        onActivated: historyViewLoader.active = true
    }

    // Ctrl+Shift+O: Show Bookmarks
    Shortcut {
        sequence: "Ctrl+Shift+O"
        enabled: tabContainer.visible
        onActivated: bookmarksViewLoader.active = true
    }

    // Alt+← or Backspace: Goes to the previous page in history
    Shortcut {
        sequence: StandardKey.Back
        enabled: tabContainer.visible
        onActivated: internal.historyGoBack()
    }

    // Alt+→ or Shift+Backspace: Goes to the next page in history
    Shortcut {
        sequence: StandardKey.Forward
        enabled: tabContainer.visible
        onActivated: internal.historyGoForward()
    }

    // F5 or Ctrl+R: Reload current Tab
    Shortcut {
        sequence: StandardKey.Refresh
        enabled: tabContainer.visible
        onActivated: if (currentWebview) currentWebview.reload()
    }
    Shortcut {
        sequence: "F5"
        enabled: tabContainer.visible
        onActivated: if (currentWebview) currentWebview.reload()
    }

    // Ctrl+F: Find in Page
    Shortcut {
        sequence: StandardKey.Find
        enabled: tabContainer.visible && !newTabViewLoader.active
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

    // Ctrl+Minus: zoom out
    Shortcut {
        sequence: StandardKey.ZoomOut
        enabled: currentWebview &&
                 ((currentWebview.zoomFactor - currentWebview.minimumZoomFactor) > 0.001)
        onActivated: internal.changeZoomFactor(-1)
    }

    // Ctrl+0: reset zoom factor to 1.0
    Shortcut {
        sequence: "Ctrl+0"
        enabled: currentWebview && (currentWebview.zoomFactor != 1.0)
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

    Loader {
        id: filePickerLoader
        source: "ContentPickerDialog.qml"
        asynchronous: true
    }
}
