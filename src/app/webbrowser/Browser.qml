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

import QtQuick 2.4
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import com.canonical.Oxide 1.8 as Oxide
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1
import "../actions" as Actions
import "../UrlUtils.js" as UrlUtils
import ".."
import "."

BrowserView {
    id: browser

    // Should be true when the containing window is fullscreen.
    property bool fullscreen: false

    currentWebview: tabsModel && tabsModel.currentTab ? tabsModel.currentTab.webview : null

    property var downloadsModel: (downloadsModelLoader.status == Loader.Ready) ? downloadsModelLoader.item : null
    property var downloadManager: (downloadHandlerLoader.status == Loader.Ready) ? downloadHandlerLoader.item : null

    property bool newSession: false

    property bool incognito: false

    readonly property var tabsModel: incognito ? privateTabsModelLoader.item : publicTabsModel

    // XXX: we might want to tweak this value depending
    // on the form factor and/or the available memory
    readonly property int maxLiveWebviews: 2

    // Restore only the n most recent tabs at startup,
    // to limit the overhead of instantiating too many
    // tab objects (see http://pad.lv/1376433).
    readonly property int maxTabsToRestore: 10

    onTabsModelChanged: {
        if (incognito && privateTabsModelLoader.item) {
            browser.openUrlInNewTab("", true)
        }
    }

    Connections {
        target: tabsModel
        onCurrentIndexChanged: {
            // Remove focus from the address bar when the current tab
            // changes to ensure that its contents are updated.
            tabContainer.forceActiveFocus()

            // In narrow mode, the tabslist is a stack:
            // the current tab is always at the top.
            if (!browser.wide) {
                tabsModel.move(tabsModel.currentIndex, 0)
            }
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
        onMediaAccessPermissionRequested: PopupUtils.open(mediaAccessDialogComponent, null, { request: request })
    }

    Component {
        id: mediaAccessDialogComponent
        MediaAccessDialog { }
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
            onTriggered: browser.openUrlInNewTab("", true)
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

    Settings {
        id: settings

        property url homepage: settingsDefaults.homepage
        property string searchEngine: settingsDefaults.searchEngine
        property string allowOpenInBackgroundTab: settingsDefaults.allowOpenInBackgroundTab
        property bool restoreSession: settingsDefaults.restoreSession
        property int newTabDefaultSection: settingsDefaults.newTabDefaultSection
        property string defaultAudioDevice
        property string defaultVideoDevice

        function restoreDefaults() {
            homepage  = settingsDefaults.homepage
            searchEngine = settingsDefaults.searchEngine
            allowOpenInBackgroundTab = settingsDefaults.allowOpenInBackgroundTab
            restoreSession = settingsDefaults.restoreSession
            newTabDefaultSection = settingsDefaults.newTabDefaultSection
            defaultAudioDevice = settingsDefaults.defaultAudioDevice
            defaultVideoDevice = settingsDefaults.defaultVideoDevice
        }
    }

    QtObject {
        id: settingsDefaults

        readonly property url homepage: "http://start.ubuntu.com"
        readonly property string searchEngine: "google"
        readonly property string allowOpenInBackgroundTab: "default"
        readonly property bool restoreSession: true
        readonly property int newTabDefaultSection: 0
        readonly property string defaultAudioDevice: ""
        readonly property string defaultVideoDevice: ""
    }

    FocusScope {
        anchors.fill: parent
        visible: !settingsContainer.visible && !historyViewLoader.active && !bookmarksViewLoader.active && !downloadsContainer.visible

        FocusScope {
            id: tabContainer
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height - osk.height
        }

        Loader {
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }
            sourceComponent: ErrorSheet {
                visible: currentWebview ? currentWebview.lastLoadFailed : false
                url: currentWebview ? currentWebview.url : ""
                onRefreshClicked: currentWebview.reload()
            }
            asynchronous: true
        }

        Loader {
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
            asynchronous: true
        }

        Loader {
            id: newTabViewLoader

            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown" && chrome.visible) ? chrome.height : 0
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
                    onReleasingKeyboardFocus: chrome.focus = true
                }
            }

            Component {
                id: newPrivateTabView

                NewPrivateTabView { anchors.fill: parent }
            }
        }

        Loader {
            anchors {
                fill: tabContainer
                topMargin: (chrome.state == "shown") ? chrome.height : 0
            }

            active: webProcessMonitor.crashed || (webProcessMonitor.killed && !currentWebview.loading)

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

        Toolbar {
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
                    browser.openUrlInNewTab("", true)
                }
            }
        }

        function reset() {
            state = ""
            recentToolbar.state = "hidden"
            tabslist.reset()
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
        defaultMode: (formFactor == "desktop") ? Oxide.LocationBarController.ModeShown
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
        onRequestNewTab: browser.openUrlInNewTab("", makeCurrent, true, index)
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
                objectName: "share"
                text: i18n.tr("Share")
                iconName: "share"
                enabled: (formFactor == "mobile") && chrome.tab && chrome.tab.url.toString()
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
                objectName: "tabs"
                text: i18n.tr("Open tabs")
                iconName: "browser-tabs"
                enabled: (formFactor != "mobile") && !browser.wide
                onTriggered: {
                    recentView.state = "shown"
                    recentToolbar.state = "shown"
                }
            },
            Action {
                objectName: "newtab"
                text: i18n.tr("New tab")
                iconName: browser.incognito ? "private-tab-new" : "tab-new"
                enabled: (formFactor != "mobile") && !browser.wide
                onTriggered: browser.openUrlInNewTab("", true)
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
                enabled: downloadHandlerLoader.status == Loader.Ready
                onTriggered: {
                    currentWebview.showDownloadsPage()
                }
            },
            Action {
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
            },
            Action {
                objectName: "settings"
                text: i18n.tr("Settings")
                iconName: "settings"
                onTriggered: {
                    settingsComponent.createObject(settingsContainer)
                    settingsContainer.focus = true
                    chrome.findInPageMode = false
                }
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

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(2)

        enabled: (formFactor == "mobile") && !browser.wide &&
                 (recentView.state == "") && browser.currentWebview &&
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
        objectName: "bottomEdgeHint"
        source: (formFactor == "mobile") ? "assets/bottom_edge_hint.png" : ""
        property bool forceShow: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: (((chrome.state == "shown") && browser.currentWebview && !browser.currentWebview.fullscreen) || forceShow) ? 0 : -height
            Behavior on bottomMargin {
                UbuntuNumberAnimation {}
            }
        }
        visible: bottomEdgeHandle.enabled
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

    Loader {
        id: bookmarksViewLoader

        anchors.fill: parent
        active: false
        sourceComponent: browser.wide ? bookmarksViewWideComponent : bookmarksViewComponent

        onStatusChanged: {
            if (status == Loader.Ready) {
                bookmarksViewLoader.item.forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }

        Keys.onEscapePressed: bookmarksViewLoader.active = false

        onActiveChanged: {
            if (active) {
                chrome.findInPageMode = false
                forceActiveFocus()
            }
        }

        Connections {
            target: bookmarksViewLoader.item

            onBookmarkEntryClicked: {
                browser.openUrlInNewTab(url, true)
                bookmarksViewLoader.active = false
            }
            onDone: bookmarksViewLoader.active = false
            onNewTabClicked: {
                browser.openUrlInNewTab("", true)
                bookmarksViewLoader.active = false
            }
        }

        Component {
            id: bookmarksViewComponent

            BookmarksView {
                anchors.fill: parent

                homepageUrl: settings.homepage
            }
        }

        Component {
            id: bookmarksViewWideComponent

            BookmarksViewWide {
                anchors.fill: parent

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
                historyViewLoader.item.loadModel()
                historyViewLoader.item.forceActiveFocus()
            } else {
                internal.resetFocus()
            }
        }

        Keys.onEscapePressed: historyViewLoader.active = false

        onActiveChanged: {
            if (active) {
                chrome.findInPageMode = false
                forceActiveFocus()
            }
        }

        Component {
            id: historyViewComponent

            HistoryView {
                anchors.fill: parent

                onSeeMoreEntriesClicked: {
                    var view = expandedHistoryViewComponent.createObject(expandedHistoryViewContainer, {model: model})
                    view.onHistoryEntryClicked.connect(done)
                }
                onDone: historyViewLoader.active = false

                FocusScope {
                    id: expandedHistoryViewContainer

                    visible: children.length > 0
                    anchors.fill: parent

                    Component {
                        id: expandedHistoryViewComponent

                        ExpandedHistoryView {
                            anchors.fill: parent

                            onHistoryEntryClicked: {
                                browser.openUrlInNewTab(url, true)
                                done()
                            }
                            onHistoryEntryRemoved: {
                                if (count == 1) {
                                    done()
                                }
                                HistoryModel.removeEntryByUrl(url)
                            }
                            onDone: destroy()
                        }
                    }
                }
            }
        }

        Component {
            id: historyViewWideComponent

            HistoryViewWide {
                anchors.fill: parent

                Keys.onEscapePressed: {
                    historyViewLoader.active = false
                    internal.resetFocus()
                }

                onHistoryEntryClicked: {
                    browser.openUrlInNewTab(url, true)
                    done()
                }

                onNewTabRequested: browser.openUrlInNewTab("", true)
                onDone: historyViewLoader.active = false
            }
        }
    }

    FocusScope {
        id: settingsContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: settingsComponent

            SettingsPage {
                anchors.fill: parent
                focus: true
                settingsObject: settings
                onDone: destroy()
                Keys.onEscapePressed: {
                    destroy()
                    internal.resetFocus()
                }
            }
        }
    }

    FocusScope {
        id: downloadsContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: downloadsComponent

            DownloadsPage {
                anchors.fill: parent
                focus: true
                downloadsModel: browser.downloadsModel
                onDone: destroy()
                Keys.onEscapePressed: {
                    destroy()
                    internal.resetFocus()
                }
            }
        }
    }

    TabsModel {
        id: publicTabsModel
    }

    Loader {
        id: privateTabsModelLoader

        sourceComponent: browser.incognito ? privateTabsModelComponent : undefined

        Component {
            id: privateTabsModelComponent

            TabsModel {
                Component.onDestruction: {
                    while (count > 0) {
                        var tab = remove(count - 1)
                        if (tab) {
                            tab.close()
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: downloadsModelLoader
        source: "DownloadsModel.qml"
        asynchronous: true
    }

    Loader {
        id: downloadHandlerLoader
        source: "DownloadHandler.qml"
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
                        onTriggered: browser.openUrlInNewTab(contextModel.linkUrl, true)
                    }
                    Actions.OpenLinkInNewBackgroundTab {
                        objectName: "OpenLinkInNewBackgroundTabContextualAction"
                        enabled: contextModel && contextModel.linkUrl.toString() &&
                                 ((settings.allowOpenInBackgroundTab === "true") ||
                                  ((settings.allowOpenInBackgroundTab === "default") &&
                                   (formFactor === "desktop")))
                        onTriggered: browser.openUrlInNewTab(contextModel.linkUrl, false)
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
                        enabled: (formFactor == "mobile") && contextModel &&
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
                        enabled: contextModel && contextModel.srcUrl.toString()
                        onTriggered: browser.openUrlInNewTab(contextModel.srcUrl, true)
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
                            browser.openUrlInNewTab("", true, true)
                        }
                    }
                }

                onLoadEvent: {
                    if (event.type == Oxide.LoadEvent.TypeCommitted) {
                        chrome.findInPageMode = false
                    }

                    if (webviewimpl.incognito) {
                        return
                    }

                    if (event.type == Oxide.LoadEvent.TypeSucceeded &&
                        300 > event.httpStatusCode && event.httpStatusCode >= 200) {
                        HistoryModel.add(event.url, title, icon)
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
                            text: (formFactor == "mobile") ?
                                      i18n.tr("Swipe Up To Exit Full Screen") :
                                      i18n.tr("Press ESC To Exit Full Screen")
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
                    downloadsContainer.focus = true
                    return downloadsComponent.createObject(downloadsContainer)
                }

                function startDownload(downloadId, download, mimeType) {
                    downloadsModel.add(downloadId, download.url, mimeType)
                    download.start()
                    showDownloadsPage()
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

            Component.onCompleted: {
                forceActiveFocus()
            }

            Component.onDestruction: {
                if (BookmarksModel.contains(bookmarkUrl)) {
                    BookmarksModel.update(bookmarkUrl, bookmarkTitle, bookmarkFolder)
                }
            }

            Keys.onPressed: {
                if (bookmarkOptionsShortcuts.processKey(event.key, event.modifiers)) {
                    event.accepted = true
                }
            }

            KeyboardShortcuts {
                id: bookmarkOptionsShortcuts
                KeyboardShortcut {
                    key: Qt.Key_Return
                    onTriggered: hide()
                }

                KeyboardShortcut {
                    key: Qt.Key_Escape
                    onTriggered: {
                        BookmarksModel.remove(bookmarkUrl)
                        hide()
                    }
                }

                KeyboardShortcut {
                    modifiers: Qt.ControlModifier
                    key: Qt.Key_D
                    onTriggered: {
                        BookmarksModel.remove(bookmarkUrl)
                        hide()
                    }
                }
            }
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

        function getOpenPages() {
            var urls = [];
            for (var i = 0; i < tabsModel.count; i++) {
                var url = tabsModel.get(i).url
                if (url.length > 0) urls.push(url) // exclude "new tab" tabs
            }
            return urls;
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

        function addTab(tab, setCurrent, index) {
            if (index === undefined) index = tabsModel.add(tab)
            else index = tabsModel.insert(tab, index)
            if (setCurrent) {
                chrome.requestedUrl = tab.initialUrl
                switchToTab(index, true)
            }
        }

        function closeTab(index) {
            // Save the incognito state before removing the tab, because
            // removing the last tab in the model will switch out incognito
            // mode, thus causing the check below to fail and save the tab
            // into the undo stack when it should be forgotten instead.
            var wasIncognito = incognito
            var tab = tabsModel.remove(index)
            if (tab) {
                if (!wasIncognito && tab.url.toString().length > 0) {
                    closedTabHistory.push({
                        state: session.serializeTabState(tab),
                        index: index
                    })
                }
                tab.close()
            }
            if (tabsModel.count === 0) {
                browser.openUrlInNewTab("", true)
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
                var tab = session.createTabFromState(tabInfo.state)
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
                    if (!tab.url.toString() && !tab.initialUrl.toString() &&
                        (formFactor == "desktop")) {
                        focusAddressBar()
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
                if (!browser.currentWebview.url.toString() && (formFactor == "desktop")) {
                    internal.focusAddressBar()
                } else {
                    tabContainer.forceActiveFocus()
                }
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

        function addBookmark(url, title, icon, location) {
            if (title == "") title = UrlUtils.removeScheme(url)
            BookmarksModel.add(url, title, icon, "")
            if (location === undefined) location = chrome.bookmarkTogglePlaceHolder
            PopupUtils.open(bookmarkOptionsComponent,
                            location,
                            {"bookmarkUrl": url,
                             "bookmarkTitle": title})
        }
    }

    // Work around https://launchpad.net/bugs/1502675 by delaying the switch to
    // the next tab for a fraction of a second to avoid a black flash.
    Timer {
        id: delayedTabSwitcher
        interval: 50
        onTriggered: internal.switchToTab(internal.nextTabIndex, false)
    }

    function openUrlInNewTab(url, setCurrent, load, index) {
        load = typeof load !== 'undefined' ? load : true
        var tab = tabComponent.createObject(tabContainer, {"initialUrl": url, 'incognito': browser.incognito})
        internal.addTab(tab, setCurrent, index)
        if (load) {
            tab.load()
        }
        if (!url.toString() && (formFactor == "desktop")) {
            internal.focusAddressBar()
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
            for (var i = 0; i < publicTabsModel.count; ++i) {
                var tab = publicTabsModel.get(i)
                tabs.push(serializeTabState(tab))
            }
            store(JSON.stringify({tabs: tabs, currentIndex: publicTabsModel.currentIndex}))
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
                    for (var i = 0; i < Math.min(tabs.length, browser.maxTabsToRestore); ++i) {
                        var tab = createTabFromState(tabs[i])
                        internal.addTab(tab, i == 0)
                    }
                }
                if ('currentIndex' in state) {
                    internal.switchToTab(state.currentIndex, true)
                }
            }
        }

        // Those two functions are used to save/restore the current state of a tab.
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

        function createTabFromState(state) {
            var properties = {'initialUrl': state.url, 'initialTitle': state.title}
            if ('uniqueId' in state) {
                properties["uniqueId"] = state.uniqueId
            }
            if ('icon' in state) {
                properties["initialIcon"] = state.icon
            }
            if ('preview' in state) {
                properties["preview"] = state.preview
            }
            if ('savedState' in state) {
                properties['restoreState'] = state.savedState
                properties['restoreType'] = Oxide.WebView.RestoreLastSessionExitedCleanly
            }
            return tabComponent.createObject(tabContainer, properties)
        }
    }
    Timer {
        id: delayedSessionSaver
        interval: 500
        onTriggered: session.save()
    }
    Timer {
        // Save session periodically to mitigate state loss when the application crashes
        interval: 60000 // every minute
        repeat: true
        running: !browser.incognito
        onTriggered: delayedSessionSaver.restart()
    }
    Timer {
        id: exitFullscreenOnLostFocus
        interval: 500
        onTriggered: {
            if (browser.currentWebview) browser.currentWebview.fullscreen = false
        }
    }
    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state != Qt.ApplicationActive) {
                if (!browser.incognito) {
                    session.save()
                }
                if (browser.currentWebview) {
                    // Workaround for a desktop bug where changing volume causes the app to
                    // briefly lose focus to notify-osd, and therefore exit fullscreen mode.
                    // We prevent this by exiting fullscreen only if the focus remains lost
                    // for longer than a certain threshold. See: http://pad.lv/1477308
                    if (formFactor == "desktop") exitFullscreenOnLostFocus.start()
                    else browser.currentWebview.fullscreen = false
                }
            } else exitFullscreenOnLostFocus.stop()
        }
        onAboutToQuit: {
            if (!browser.incognito) {
                session.save()
            }
        }
    }
    Connections {
        target: browser.incognito ? null : publicTabsModel
        onCurrentTabChanged: delayedSessionSaver.restart()
        onCountChanged: delayedSessionSaver.restart()
    }
    onIncognitoChanged: {
        if (incognito) {
            // When going incognito, save the current session right
            // away, as periodic session saving is disabled.
            session.save()
        }
    }

    // Schedule various expensive tasks to a point after the initialization and
    // first rendering of the application have already happened.
    //
    // Scheduling a Timer with the shortest non-zero interval possible (1ms) will
    // effectively queue its onTriggered function to run immediately after anything
    // that is currently in the event loop queue at the moment the Timer starts.
    //
    // The tasks are:
    // - creating the webviews for all initial tabs. This should ideally be done
    //   asynchronously via object incubation, but http://pad.lv/1359911 prevents it
    // - loading the HistoryModel and BookmarksModel from the database
    // - deleting any page screenshots that are no longer needed
    Timer {
        running: true
        interval: 1
        onTriggered: {
            if (!browser.newSession && settings.restoreSession) {
                session.restore()
            }

            // Sanity check
            console.assert(tabsModel.count <= browser.maxTabsToRestore,
                           "WARNING: too many tabs were restored")
            for (var i in browser.initialUrls) {
                browser.openUrlInNewTab(browser.initialUrls[i], true, false)
            }
            if (tabsModel.count == 0) {
                browser.openUrlInNewTab(settings.homepage, true, false)
            }
            tabsModel.currentTab.load()
            if (!tabsModel.currentTab.url.toString() && !tabsModel.currentTab.restoreState && (formFactor == "desktop")) {
                internal.focusAddressBar()
            }

            BookmarksModel.databasePath = dataLocation + "/bookmarks.sqlite"
            HistoryModel.databasePath = dataLocation + "/history.sqlite"

            // Note that the property setter for databasePath won't return until
            // the entire model has been loaded, so it is safe to call this here
            PreviewManager.cleanUnusedPreviews(internal.getOpenPages())
        }
    }

    Connections {
        // On mobile, ensure that at most n webviews are instantiated at all
        // times, to reduce memory consumption (see http://pad.lv/1376418).
        // Note: this works only in narrow mode, where the list of tabs is a
        // stack. Switching from wide mode to narrow mode will result in
        // undefined behaviour (tabs previously loaded won’t be unloaded).
        target: ((formFactor == "mobile") && !browser.wide) ? tabsModel : null
        onCurrentTabChanged: {
            if (tabsModel.count > browser.maxLiveWebviews) {
                tabsModel.get(browser.maxLiveWebviews).unload()
            }
        }
    }

    Connections {
        target: tabsModel
        onCurrentTabChanged: {
            chrome.findInPageMode = false
            var tab = tabsModel.currentTab
            if (tab) {
                tab.load()
            }
            internal.resetFocus()
        }
        onCountChanged: {
            if (tabsModel.count == 0) {
                if (browser.incognito) {
                    browser.incognito = false
                    internal.resetFocus()
                } else if ((formFactor == "desktop") || browser.wide) {
                    Qt.quit()
                }
            }
        }
    }

    Component {
        id: leavePrivateModeDialog

        LeavePrivateModeDialog {
            id: dialogue
            objectName: "leavePrivateModeDialog"

            // This dialog inherits from PopupBase, which has a restoreActiveFocus
            // function that is called when the dialog is hidden. That keeps the
            // focus in the address bar/webview when we leave private mode. So any
            // change on the active focus should be done after the run of such
            // function
            Component.onDestruction: {
                if (!browser.incognito) {
                    internal.resetFocus()
                }
            }

            onCancelButtonClicked: PopupUtils.close(dialogue)
            onOkButtonClicked: {
                PopupUtils.close(dialogue)
                browser.incognito = false
            }
        }
    }

    Keys.onPressed: if (shortcuts.processKey(event.key, event.modifiers)) event.accepted = true
    KeyboardShortcuts {
        id: shortcuts

        // Ctrl+Tab or Ctrl+PageDown: cycle through open tabs
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_Tab
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.switchToNextTab()
        }
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_PageDown
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.switchToNextTab()
        }

        // Ctrl+Shift+Tab or Ctrl+PageUp: cycle through open tabs in reverse order
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_Backtab
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.switchToPreviousTab()
        }
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_PageUp
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.switchToPreviousTab()
        }

        // Ctrl+Shift+W or Ctrl+Shift+T: Undo close tab
        KeyboardShortcut {
            modifiers: Qt.ControlModifier | Qt.ShiftModifier
            key: Qt.Key_W
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.undoCloseTab()
        }

        KeyboardShortcut {
            modifiers: Qt.ControlModifier | Qt.ShiftModifier
            key: Qt.Key_T
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.undoCloseTab()
        }

        // Ctrl+W or Ctrl+F4: Close the current tab
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_W
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.closeCurrentTab()
        }
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_F4
            enabled: (chrome.visible || recentView.visible) && !downloadsContainer.visible
            onTriggered: internal.closeCurrentTab()
        }

        // Ctrl+T: Open a new Tab
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_T
            enabled: (chrome.visible || recentView.visible || bookmarksViewLoader.active || historyViewLoader.active) && !downloadsContainer.visible
            onTriggered: {
                openUrlInNewTab("", true)
                if (recentView.visible) recentView.reset()

                bookmarksViewLoader.active = false
                historyViewLoader.active = false
            }
        }

        // F6 or Ctrl+L or Alt+D: Select the content in the address bar
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_L
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.focusAddressBar(true)
        }
        KeyboardShortcut {
            modifiers: Qt.AltModifier
            key: Qt.Key_D
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.focusAddressBar(true)
        }
        KeyboardShortcut {
            key: Qt.Key_F6
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.focusAddressBar(true)
        }

        // Ctrl+D: Toggle bookmarked state on current Tab
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_D
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: {
                if (currentWebview) {
                    if (BookmarksModel.contains(currentWebview.url)) {
                        BookmarksModel.remove(currentWebview.url)
                    } else {
                        internal.addBookmark(currentWebview.url, currentWebview.title, currentWebview.icon)
                    }
                }
            }
        }

        // Ctrl+H: Show History
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_H
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: historyViewLoader.active = true
        }

        // Ctrl+Shift+O: Show Bookmarks
        KeyboardShortcut {
            modifiers: Qt.ControlModifier | Qt.ShiftModifier
            key: Qt.Key_O
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: bookmarksViewLoader.active = true
        }

        // Alt+← or Backspace: Goes to the previous page in history
        KeyboardShortcut {
            modifiers: Qt.AltModifier
            key: Qt.Key_Left
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.historyGoBack()
        }
        KeyboardShortcut {
            key: Qt.Key_Backspace
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.historyGoBack()
        }

        // Alt+→ or Shift+Backspace: Goes to the next page in history
        KeyboardShortcut {
            modifiers: Qt.AltModifier
            key: Qt.Key_Right
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.historyGoForward()
        }
        KeyboardShortcut {
            modifiers: Qt.ShiftModifier
            key: Qt.Key_Backspace
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: internal.historyGoForward()
        }

        // F5 or Ctrl+R: Reload current Tab
        KeyboardShortcut {
            key: Qt.Key_F5
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: if (currentWebview) currentWebview.reload()
        }
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_R
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: if (currentWebview) currentWebview.reload()
        }

        // Ctrl + F: Find in Page
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_F
            enabled: !newTabViewLoader.active && !bookmarksViewLoader.active && !downloadsContainer.visible
            onTriggered: chrome.findInPageMode = true
        }

        // Ctrl + J: Show downloads page
        KeyboardShortcut {
            modifiers: Qt.ControlModifier
            key: Qt.Key_J
            enabled: chrome.visible && !downloadsContainer.visible
            onTriggered: currentWebview.showDownloadsPage()
        }
    }

    Loader {
        id: contentHandlerLoader
        source: "ContentHandler.qml"
    }

    Connections {
        target: contentHandlerLoader.item
        onExportFromDownloads: {
            if (downloadHandlerLoader.status == Loader.Ready) {
                downloadsContainer.focus = true
                var downloadPage = downloadsComponent.createObject(downloadsContainer)
                downloadPage.mimetypeFilter = mimetypeFilter
                downloadPage.activeTransfer = transfer
                downloadPage.multiSelect = multiSelect
                downloadPage.pickingMode = true
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
