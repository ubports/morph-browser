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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "."
import ".."
import webbrowsercommon.private 0.1

import "Tabs" as Tabs

ChromeBase {
    id: chrome

    property var tabsModel
    property alias tab: navigationBar.tab
    readonly property var webview: tab ? tab.webview : null
    property alias searchUrl: navigationBar.searchUrl
    property alias text: navigationBar.text
    property alias bookmarked: navigationBar.bookmarked
    signal toggleBookmark()
    property alias drawerActions: navigationBar.drawerActions
    property alias drawerOpen: navigationBar.drawerOpen
    property alias requestedUrl: navigationBar.requestedUrl
    property alias canSimplifyText: navigationBar.canSimplifyText
    property alias findInPageMode: navigationBar.findInPageMode
    property alias editing: navigationBar.editing
    property alias incognito: navigationBar.incognito
    property alias showTabsBar: tabsBar.visible
    property alias showFaviconInAddressBar: navigationBar.showFaviconInAddressBar
    property alias availableHeight: navigationBar.availableHeight
    readonly property alias bookmarkTogglePlaceHolder: navigationBar.bookmarkTogglePlaceHolder
    property bool touchEnabled: true
    readonly property real tabsBarHeight: tabsBar.height + tabsBar.anchors.topMargin
    property BrowserWindow thisWindow
    property DropArea dropArea

    signal switchToTab(int index)
    signal requestNewTab(int index, bool makeCurrent)
    signal requestNewWindowFromTab(var tab, var callback)
    signal tabClosed(int index, bool moving)

    backgroundColor: incognito ? UbuntuColors.darkGrey : "#ffffff"

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
            color: (showTabsBar || !incognito) ? "#ffffff" : UbuntuColors.darkGrey
        }

        Tabs.TabsBar {
            id: tabsBar
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: units.gu(1)
            }
            dragAndDrop {
                dropArea: chrome.dropArea
                enabled: true
                mimeType: "webbrowser/tab-" + (chrome.incognito ? "incognito" : "public")
                previewTopCrop: chrome.height
                previewUrlFromIndex: function(index) {
                     return PreviewManager.previewPathFromUrl(tabsModel.get(index).url)
                }
                thisWindow: chrome.thisWindow
            }
            model: chrome.tabsModel

            onContextMenu: PopupUtils.open(contextualOptionsComponent, tabDelegate, {"targetIndex": index})
            onRequestNewWindowFromTab: chrome.requestNewWindowFromTab(tab, callback)

            fallbackIcon: "stock_website"

            property Component faviconFactory: Component {
                FaviconFetcher {

                }
            }

            function iconSourceFromModelItem(modelData, index) {
                var incubator = faviconFactory.incubateObject(
                    parent,
                    {
                        "shouldCache": Qt.binding(function() { return !incognito; }),
                        "url": Qt.binding(function() { return modelData.icon; })
                    }
                );
                return incubator.status == Component.Ready ? incubator.object.localUrl || "" : "";
            }

            function removeTabButMoving(index) {
                model.removeTab(index, true);  // uses overloaded removeTab
            }

            function titleFromModelItem(modelItem) {
                return modelItem.title ? modelItem.title : (modelItem.url.toString() ? modelItem.url : i18n.tr("New tab"))
            }

            actions: [
                Action {
                    // FIXME: icon from theme is fuzzy at many GUs
//                     iconSource: Qt.resolvedUrl("Tabs/tab_add.png")
                    iconName: "add"
                    objectName: "newTabButton"
                    onTriggered: tabsBar.model.addTab()
                }
            ]
        }

        NavigationBar {
            id: navigationBar

            loading: chrome.loading
            fgColor: "#111111"
            iconColor: (incognito && !showTabsBar) ? "white" : fgColor

            focus: true

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: units.gu(7)

            onToggleBookmark: chrome.toggleBookmark()
        }
    }

    // Delay changing the 'loading' state, to allow for very brief load
    // sequences to not update the UI, which would result in inelegant
    // flickering (https://launchpad.net/bugs/1611680).
    Connections {
        target: webview
        onLoadingStateChanged: delayedLoadingNotifier.restart()
    }
    Timer {
        id: delayedLoadingNotifier
        interval: 100
        onTriggered: loading = webview.loading
    }

    loadProgress: (loading && webview) ? webview.loadProgress : 0

    // If the webview changes the use the loading state of the new webview
    // otherwise opening a new tab/window while another webview was loading
    // can cause a progress bar to be left behind at zero percent pad.lv/1638337
    onWebviewChanged: loading = webview ? webview.loading : false

    Component {
        id: contextualOptionsComponent
        ActionSelectionPopover {
            id: menu
            objectName: "tabContextualActions"
            property int targetIndex
            readonly property var tab: chrome.tabsModel.get(targetIndex)

            actions: ActionList {
                Action {
                    objectName: "tab_action_new_tab"
                    text: i18n.tr("New Tab")
                    onTriggered: chrome.requestNewTab(menu.targetIndex + 1, false)
                }
                Action {
                    objectName: "tab_action_reload"
                    text: i18n.tr("Reload")
                    enabled: menu.tab.url.toString().length > 0
                    onTriggered: menu.tab.reload()
                }
                Action {
                    objectName: "tab_action_move_to_new_window"
                    text: i18n.tr("Move to New Window")
                    onTriggered: {
                        // callback function only removes from model
                        // and not destroy as webview is in new window
                        chrome.requestNewWindowFromTab(menu.tab, function() { chrome.tabClosed(menu.targetIndex, true); });
                    }
                }
                Action {
                    objectName: "tab_action_close_tab"
                    text: i18n.tr("Close Tab")
                    onTriggered: chrome.tabClosed(menu.targetIndex, false)
                }
            }
        }
    }
}
