/*
 * Copyright 2013-2017 Canonical Ltd.
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

import QtQuick 2.5
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import "."
import ".."
import webbrowsercommon.private 0.1
import webbrowserapp.private 0.1

QtObject {
    id: webbrowserapp

    function init(urls, newSession, incognito) {
        i18n.domain = "morph-browser"
        if (!newSession && settings.restoreSession && ! (incognito || settings.incognitoOnStart)) {
            session.restore();
        }
        if (allWindows.length == 0) {
            windowFactory.createObject(null, {"incognito": (incognito || settings.incognitoOnStart)}).show();
        }
        var window = allWindows[allWindows.length - 1];
        for (var i in urls) {
            window.addTab(urls[i]).load();
            window.tabsModel.currentIndex = window.tabsModel.count - 1;
        }
        if (window.tabsModel.count === 0) {
            window.addTab(settings.homepage).load();
            window.tabsModel.currentIndex = 0;
        }
        for (var w in allWindows) {
            allWindows[w].tabsModel.currentTab.load();
        }

        // FIXME: do this asynchronously
        BookmarksModel.databasePath = dataLocation + "/bookmarks.sqlite";
        HistoryModel.databasePath = dataLocation + "/history.sqlite";
        DownloadsModel.databasePath = dataLocation + "/downloads.sqlite";
        DomainPermissionsModel.databasePath = dataLocation + "/domainpermissions.sqlite";
        DomainPermissionsModel.whiteListMode = settings.domainWhiteListMode;
        DomainSettingsModel.defaultZoomFactor = settings.zoomFactor;
        DomainSettingsModel.databasePath = dataLocation + "/domainsettings.sqlite";
        UserAgentsModel.databasePath = DomainSettingsModel.databasePath;
    }

    // Array of all windows, sorted chronologically (most recently active last)
    readonly property var allWindows: []

    function getLastActiveWindow(incognito) {
        for (var i = allWindows.length - 1; i >= 0; --i) {
            var window = allWindows[i]
            if (window.incognito === incognito) {
                return window
            }
        }
        return null
    }

    function openUrls(urls, newWindow, incognito) {
        var window = getLastActiveWindow(incognito)
        if (!window || newWindow) {
            window = windowFactory.createObject(null, {"incognito": incognito})
        }
        for (var i in urls) {
            window.addTab(urls[i]).load()
        }
        if (window.tabsModel.count === 0) {
            window.addTab().load()
        }
        window.tabsModel.currentIndex = window.tabsModel.count - 1
        window.show()
        window.requestActivate()
    }

    property var windowFactory: Component {
        BrowserWindow {
            id: window

            property alias incognito: browser.incognito
            readonly property alias model: browser.tabsModel
            readonly property var tabsModel: browser.tabsModel

            currentWebview: browser.currentWebview

            title: {
                if (browser.title) {
                    // TRANSLATORS: %1 refers to the current page’s title
                    return i18n.tr("%1 - Morph Web Browser").arg(browser.title)
                } else {
                    return i18n.tr("Morph Web Browser")
                }
            }

            onActiveChanged: {
                if (active) {
                    var index = allWindows.indexOf(this)
                    if (index > -1) {
                        allWindows.push(allWindows.splice(index, 1)[0])
                    }
                }
            }

            onClosing: {
                if (allWindows.length == 1) {
                    if (tabsModel.count > 0) {
                        session.save()
                    } else {
                        session.clear()
                    }
                }

                if (incognito && (allWindows.length > 1)) {
                    // If the last incognito window is being closed,
                    // prune incognito entries from the downloads model
                    var incognitoWindows = 0
                    for (var w in allWindows) {
                        var window = allWindows[w]
                        if ((window !== this) && window.incognito) {
                            ++incognitoWindows
                        }
                    }
                    if (incognitoWindows == 0) {
                        DownloadsModel.pruneIncognitoDownloads()
                    }
                }



                if (allWindows.length > 1)
                {
                    for (var win in allWindows) {
                        if (this === allWindows[win]) {
                            var tabs = allWindows[win].tabsModel
                            for (var t = tabs.count - 1; t >= 0; --t) {
                                //console.log("remove tab with url " + tabs.get(t).url)
                                tabs.removeTab(t)
                            }
                            allWindows.splice(win, 1)
                            return
                        }
                    }
                }

                destroy()
            }

            Shortcut {
                sequence: StandardKey.Quit
                onActivated: Qt.quit()
            }

            function toggleApplicationLevelFullscreen() {
                setFullscreen(visibility !== Window.FullScreen)
            }

            Shortcut {
                sequence: StandardKey.FullScreen
                onActivated: window.toggleApplicationLevelFullscreen()
            }

            Shortcut {
                sequence: "F11"
                onActivated: window.toggleApplicationLevelFullscreen()
            }

            Shortcut {
                sequence: "Ctrl+N"
                onActivated: browser.newWindowRequested(false)
            }

            Shortcut {
                sequence: "Ctrl+Shift+N"
                onActivated: browser.newWindowRequested(true)
            }

            Component.onCompleted: allWindows.push(this)

            Browser {
                id: browser
                anchors.fill: parent
                thisWindow: window
                settings: webbrowserapp.settings
                windowFactory: webbrowserapp.windowFactory
                onNewWindowRequested: {
                    var window = windowFactory.createObject(
                        null,
                        {
                            "incognito": incognito,
                            "height": parent.height,
                            "width": parent.width,
                        }
                    )

                    window.addTab()
                    window.tabsModel.currentIndex = 0
                    window.tabsModel.currentTab.load()
                    window.show()

                }
                onOpenLinkInNewWindowRequested: {
                    var window = windowFactory.createObject(
                        null,
                        {
                            "incognito": incognito,
                            "height": parent.height,
                            "width": parent.width,
                        }
                    )
                    window.addTab(url)
                    window.tabsModel.currentIndex = window.tabsModel.count - 1
                    window.tabsModel.currentTab.load()
                    window.show()
                    window.requestActivate()
                }

                onOpenLinkInNewTabRequested: {

                    window.addTab(url);

                    if (! background)
                    {
                        window.tabsModel.currentIndex = window.tabsModel.count - 1
                        window.tabsModel.currentTab.load()
                    }
                }

                // Not handled as a window-level shortcut as it would take
                // precedence over key events in web content.
                Keys.onEscapePressed: {
                    // ESC to exit fullscreen, regardless of whether it was
                    // requested by the page or toggled on by the user.
                    window.setFullscreen(false)
                }
            }

            Connections {
                target: window.tabsModel
                onCountChanged: {
                    if ((window.tabsModel.count === 0) && browser.wide) {
                        window.close()
                    }
                }
            }

            Connections {
                target: window.incognito ? null : window.tabsModel
                onCurrentIndexChanged: delayedSessionSaver.restart()
                onCountChanged: delayedSessionSaver.restart()
            }

            Connections {
                target: (session.restoring || !window.visible || browser.wide) ? null : window.tabsModel
                onCurrentIndexChanged: {
                    // In narrow mode, the tabslist is a stack:
                    // the current tab is always at the top.
                    window.tabsModel.move(window.tabsModel.currentIndex, 0)
                }
            }

            function serializeTabState(tab) {
                return browser.serializeTabState(tab)
            }

            function restoreTabState(state) {
                return browser.restoreTabState(state)
            }

            function addTab(url) {
                var tab = browser.createTab({"initialUrl": url || ""})
                tabsModel.add(tab)
                return tab
            }
        }
    }

    property var settings: Settings {
        property url homepage: ""
        property string searchEngine: "duckduckgo"
        property bool restoreSession: true
        property bool setDesktopMode: false
        property bool autoFitToWidthEnabled: false
        property real zoomFactor: 1.0
        property int newTabDefaultSection: 0
        property string defaultAudioDevice: ""
        property string defaultVideoDevice: ""
        property bool domainWhiteListMode: false
        property bool incognitoOnStart: false

        function restoreDefaults() {
            homepage = ""
            searchEngine = "duckduckgo";
            restoreSession = true;
            setDesktopMode = false;
            autoFitToWidthEnabled = false;
            zoomFactor = 1.0;
            newTabDefaultSection = 0;
            defaultAudioDevice = "";
            defaultVideoDevice = "";
            domainWhiteListMode = false;
            incognitoOnStart = false;
        }

        function resetDomainPermissions() {
            DomainPermissionsModel.deleteAndResetDataBase();
        }

        function resetDomainSettings() {
            DomainSettingsModel.deleteAndResetDataBase();
            // it is a common database with DomainSettingsModel, so it is only for reset here
            UserAgentsModel.deleteAndResetDataBase();
        }
    }

    // Handle runtime requests to open urls as defined
    // by the freedesktop application dbus interface's open
    // method for DBUS application activation:
    // http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#dbus
    // The dispatch on the org.freedesktop.Application if is done per appId at the
    // url-dispatcher/upstart level.
    property var openUrlsHandler: Connections {
        target: UriHandler
        onOpened: webbrowserapp.openUrls(uris, false, settings.incognitoOnStart)
    }

    property var session: SessionStorage {
        dataFile: dataLocation + "/session.json"

        function save() {
            if (!locked || restoring) {
                return
            }
            var windows = []
            for (var w in allWindows) {
                var window = allWindows[w]
                if (window.incognito) {
                    continue
                }
                windows.push(serializeWindowState(window))
            }
            if (windows.length > 0) {
                store(JSON.stringify({windows: windows}))
            }
        }

        property bool restoring: false
        function restore() {
            restoring = true
            _doRestore()
            restoring = false
        }
        function _doRestore() {
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
                var windows = state.windows
                if (windows) {
                    for (var w in windows) {
                        restoreWindowState(windows[w])
                    }
                } else if (state.tabs) {
                    // One-off code path: when launching the app for the first time
                    // after the upgrade that adds support for multiple windows, the
                    // saved session contains a list of tabs, not windows.
                    restoreWindowState(state)
                }
                if (allWindows.length > 0) {
                    var window = allWindows[allWindows.length - 1]
                    window.requestActivate()
                    window.raise()
                }
            }
        }

        function serializeWindowState(window) {
            var tabs = []
            for (var i = 0; i < window.tabsModel.count; ++i) {
                tabs.push(window.serializeTabState(window.tabsModel.get(i)))
            }
            return {tabs: tabs, currentIndex: window.tabsModel.currentIndex,
                    width: window.width, height: window.height}
        }

        function restoreWindowState(state) {
            var windowProperties = {}
            if (state.width) {
                windowProperties["width"] = state.width
            }
            if (state.height) {
                windowProperties["height"] = state.height
            }
            var window = windowFactory.createObject(null, windowProperties)
            for (var i in state.tabs) {
                window.tabsModel.add(window.restoreTabState(state.tabs[i]))
            }
            window.tabsModel.currentIndex = state.currentIndex
            window.show()
        }

        function clear() {
            if (!locked) {
                return
            }
            store("")
        }
    }

    property var delayedSessionSaver: Timer {
        interval: 500
        onTriggered: session.save()
    }

    property var periodicSessionSaver: Timer {
        // Save session periodically to mitigate state loss when the application crashes
        interval: 60000 // every minute
        repeat: true
        running: true
        onTriggered: delayedSessionSaver.restart()
    }

    property var applicationMonitor: Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state !== Qt.ApplicationActive) {
                session.save()
            }
        }
        onAboutToQuit: {
            if (allWindows.length > 0) {
                session.save()
            }
        }
    }

    property var memoryPressureMonitor: Connections {
        target: MemInfo
        onFreeChanged: {
            var freeMemRatio = (MemInfo.total > 0) ? (MemInfo.free / MemInfo.total) : 1.0
            var lowMemoryThresholdPercent = 0.2;
            // Under that threshold, available memory is considered "low", and the
            // browser is going to try and free up memory from unused tabs. This
            // value was chosen empirically, it is subject to change to better
            // reflect what a system under memory pressure might look like.
            if (freeMemRatio < lowMemoryThresholdPercent) {
                // Unload an inactive tab to (hopefully) free up some memory
                function getCandidate(model) {
                    // Naive implementation that only takes into account the
                    // last time a tab was current. In the future we might
                    // want to take into account other parameters such as
                    // whether the tab is currently playing audio/video.
                    var candidate = null
                    for (var i = 0; i < model.count; ++i) {
                        var tab = model.get(i)
                        if (tab.current || !tab.webview) {
                            continue
                        }
                        if (!candidate || (candidate.lastCurrent > tab.lastCurrent)) {
                            candidate = tab
                        }
                    }
                    return candidate
                }
                for (var w in allWindows) {
                    var candidate = getCandidate(allWindows[w].tabsModel)
                    if (candidate) {
                        if (allWindows[w].incognito) {
                            console.warn("Unloading a background incognito tab to free up some memory")
                        } else {
                            console.warn("Unloading background tab (%1) to free up some memory".arg(candidate.url))
                        }
                        candidate.unload()
                        return
                    }
                }
                console.warn("System low on memory, but unable to pick a tab to unload")
            }
        }
    }

    property var historyModelMonitor: Connections {
        target: HistoryModel
        onLoaded: {
            var doNotCleanUrls = []
            for (var x in allWindows) {
                var tabs = allWindows[x].tabsModel
                for (var t = 0; t < tabs.count; ++t) {
                    doNotCleanUrls.push(tabs.get(t).url)
                }
            }
            PreviewManager.cleanUnusedPreviews(doNotCleanUrls)
        }
    }

    //Component.onCompleted: console.info("morph-browser using oxide %1 (chromium %2)".arg(Oxide.version).arg(Oxide.chromiumVersion))
}
