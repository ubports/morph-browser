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
import Ubuntu.Components 1.3
import ".."
import webbrowsercommon.private 0.1
import webbrowserapp.private 0.1

QtObject {
    id: webbrowserapp

    function init(urls, newSession, incognito) {
        i18n.domain = "webbrowser-app"
        if (!newSession && settings.restoreSession && !incognito) {
            session.restore()
        }
        if (allWindows.length == 0) {
            windowFactory.createObject(null, {"incognito": incognito}).show()
        }
        var window = allWindows[allWindows.length - 1]
        for (var i in urls) {
            window.addTab(urls[i]).load()
            window.tabsModel.currentIndex = window.tabsModel.count - 1
        }
        if (window.tabsModel.count == 0) {
            window.addTab(incognito ? "" : settings.homepage).load()
            window.tabsModel.currentIndex = 0
        }
        for (var w in allWindows) {
            allWindows[w].tabsModel.currentTab.load()
        }

        // FIXME: do this async
        BookmarksModel.databasePath = dataLocation + "/bookmarks.sqlite"
        HistoryModel.databasePath = dataLocation + "/history.sqlite"
        DownloadsModel.databasePath = dataLocation + "/downloads.sqlite"
        //PreviewManager.cleanUnusedPreviews(internal.getOpenPages())
    }

    // Array of all windows, sorted chronologically (most recently active last)
    readonly property var allWindows: []

    function getLastActiveWindow(incognito) {
        for (var i = allWindows.length - 1; i >= 0; --i) {
            var window = allWindows[i]
            if (window.incognito == incognito) {
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
        if (window.tabsModel.count == 0) {
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
            readonly property var tabsModel: browser.tabsModel

            currentWebview: browser.currentWebview
            
            title: {
                if (browser.title) {
                    // TRANSLATORS: %1 refers to the current page’s title
                    return i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
                } else {
                    return i18n.tr("Ubuntu Web Browser")
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
                destroy()
            }

            function toggleApplicationLevelFullscreen() {
                setFullscreen(visibility !== Window.FullScreen)
                if (browser.currentWebview.fullscreen) {
                    browser.currentWebview.fullscreen = false
                }
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
            Component.onDestruction: {
                for (var w in allWindows) {
                    if (this === allWindows[w]) {
                        allWindows.splice(w, 1)
                        return
                    }
                }
            }

            Browser {
                id: browser
                anchors.fill: parent
                settings: webbrowserapp.settings
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
                onOpenLinkInWindowRequested: {
                    var window = null
                    if (incognito) {
                        window = getLastActiveWindow(true)
                    }
                    if (!window) {
                        window = windowFactory.createObject(
                            null,
                            {
                                "incognito": incognito,
                                "height": parent.height,
                                "width": parent.width,
                            }
                        )
                    }
                    window.addTab(url)
                    window.tabsModel.currentIndex = window.tabsModel.count - 1
                    window.tabsModel.currentTab.load()
                    window.show()
                    window.requestActivate()
                }

                // Not handled as a window-level shortcut as it would take
                // precedence over key events in web content.
                Keys.onEscapePressed: {
                    // ESC to exit fullscreen, regardless of whether it was
                    // requested by the page or toggled on by the user.
                    window.setFullscreen(false)
                    browser.currentWebview.fullscreen = false
                }
            }

            Connections {
                target: window.tabsModel
                onCountChanged: {
                    if (window.tabsModel.count == 0) {
                        window.close()
                    }
                }
            }

            Connections {
                target: window.incognito ? null : window.tabsModel
                onCurrentIndexChanged: delayedSessionSaver.restart()
                onCountChanged: delayedSessionSaver.restart()
            }

            function serializeTabState(tab) {
                return browser.serializeTabState(tab)
            }

            function restoreTabState(state) {
                return browser.restoreTabState(state)
            }

            function addTab(url) {
                var tab = browser.createTab({"initialUrl": url})
                tabsModel.add(tab)
                return tab
            }
        }
    }

    property var settings: Settings {
        property url homepage: "http://start.ubuntu.com"
        property string searchEngine: "google"
        property bool restoreSession: true
        property int newTabDefaultSection: 0
        property string defaultAudioDevice: ""
        property string defaultVideoDevice: ""

        function restoreDefaults() {
            homepage  = "http://start.ubuntu.com"
            searchEngine = "google"
            restoreSession = true
            newTabDefaultSection = 0
            defaultAudioDevice = ""
            defaultVideoDevice = ""
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
        onOpened: webbrowserapp.openUrls(uris, false, false)
    }

    property var session: SessionStorage {
        dataFile: dataLocation + "/session.json"

        // TODO: do we want to save/restore window positions too (https://launchpad.net/bugs/1312892)?

        function save() {
            if (!locked) {
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
            return {tabs: tabs, currentIndex: window.tabsModel.currentIndex}
        }

        function restoreWindowState(state) {
            var window = windowFactory.createObject(null)
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
            if (Qt.application.state != Qt.ApplicationActive) {
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
            // Under that threshold, available memory is considered "low", and the
            // browser is going to try and free up memory from unused tabs. This
            // value was chosen empirically, it is subject to change to better
            // reflect what a system under memory pressure might look like.
            var lowOnMemory = (freeMemRatio < 0.2)
            if (lowOnMemory) {
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
                        if (browser.incognito) {
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
}
