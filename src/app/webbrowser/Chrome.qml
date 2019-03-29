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

import QtQuick 2.4
import Ubuntu.Components 1.3
import QtWebEngine 1.5
import ".."

ChromeBase {
    id: chrome

    property var tabsModel
    property alias tab: navigationBar.tab
    readonly property var webview: tab ? tab.webview : null
    property alias searchUrl: navigationBar.searchUrl
    property alias text: navigationBar.text
    property alias bookmarked: navigationBar.bookmarked
    signal closeTabRequested()
    signal toggleBookmark()
    property alias drawerActions: navigationBar.drawerActions
    property alias drawerOpen: navigationBar.drawerOpen
    property alias requestedUrl: navigationBar.requestedUrl
    property alias canSimplifyText: navigationBar.canSimplifyText
    property alias findInPageMode: navigationBar.findInPageMode
    property alias tabListMode: navigationBar.tabListMode
    property alias contextMenuVisible: navigationBar.contextMenuVisible
    property alias editing: navigationBar.editing
    property alias incognito: navigationBar.incognito
    property alias showTabsBar: tabsBar.active
    property alias showFaviconInAddressBar: navigationBar.showFaviconInAddressBar
    property alias availableHeight: navigationBar.availableHeight
    readonly property alias bookmarkTogglePlaceHolder: navigationBar.bookmarkTogglePlaceHolder
    property bool touchEnabled: true
    readonly property real tabsBarHeight: tabsBar.height + tabsBar.anchors.topMargin + content.anchors.topMargin
    property BrowserWindow thisWindow
    property Component windowFactory
    property bool tabsBarDimmed: false

    signal switchToTab(int index)
    signal requestNewTab(int index, bool makeCurrent)
    signal tabClosed(int index, bool moving)

    backgroundColor: incognito ? UbuntuColors.darkGrey : theme.palette.normal.background

    implicitHeight: tabsBar.height + navigationBar.height + content.anchors.topMargin

    function selectAll() {
        navigationBar.selectAll()
    }

    FocusScope {
        id: content
        anchors.fill: parent

        focus: true

        Rectangle {
            anchors.fill: navigationBar
            color: (showTabsBar || !incognito) ? theme.palette.normal.background : theme.palette.selected.base
        }

        Loader {
            id: tabsBar
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            asynchronous: true
            height: active ? units.gu(3) : 0

            Component.onCompleted: {
                setSource(
                    Qt.resolvedUrl("TabsBar.qml"),
                    {
                        "dimmed": Qt.binding(function() { return chrome.tabsBarDimmed; }),
                        "model": Qt.binding(function() { return chrome.tabsModel; }),
                        "incognito": Qt.binding(function() { return chrome.incognito; }),
                        "dragAndDrop.previewTopCrop": Qt.binding(function() { return chrome.height; }),
                        "dragAndDrop.thisWindow": Qt.binding(function() { return chrome.thisWindow; }),
                        "windowFactory": Qt.binding(function() { return chrome.windowFactory; }),
                    }
                )
            }

            Connections {
                target: tabsBar.item

                onRequestNewTab: chrome.requestNewTab(index, makeCurrent)
                onTabClosed: chrome.tabClosed(index, moving)
            }
        }

        NavigationBar {
            id: navigationBar

            loading: chrome.loading
            fgColor: theme.palette.normal.backgroundText
            iconColor: (incognito && !showTabsBar) ? theme.palette.normal.background : fgColor

            focus: true

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: units.gu(6)

            onCloseTabRequested: chrome.closeTabRequested()
            onToggleBookmark: chrome.toggleBookmark()
        }
    }

    // Delay changing the 'loading' state, to allow for very brief load
    // sequences to not update the UI, which would result in inelegant
    // flickering (https://launchpad.net/bugs/1611680).
    Connections {
        target: webview
        onLoadingChanged: delayedLoadingNotifier.restart()
    }
    Timer {
        id: delayedLoadingNotifier
        interval: 100
        onTriggered: loading = webview.loading && webview.loadProgress !== 100
    }

    loadProgress: (loading && webview) ? webview.loadProgress : 0

    // If the webview changes the use the loading state of the new webview
    // otherwise opening a new tab/window while another webview was loading
    // can cause a progress bar to be left behind at zero percent pad.lv/1638337
    onWebviewChanged: loading = webview ? webview.loading &&
                                          webview.loadProgress !== 100 : false
}
