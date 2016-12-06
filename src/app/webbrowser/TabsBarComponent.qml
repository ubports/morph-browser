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

Tabs.TabsBar {
    id: tabsBar
    anchors {
        fill: parent
    }
    dragAndDrop {
        enabled: true
        maxYDiff: height / 12
        mimeType: "webbrowser/tab-" + (incognito ? "incognito" : "public")
        previewUrlFromIndex: function(index) {
                return PreviewManager.previewPathFromUrl(tabsBar.model.get(index).url)
        }
    }
    fallbackIcon: "stock_website"

    property bool incognito

    signal requestNewTab(int index, bool makeCurrent)
    signal tabClosed(int index, bool moving)

    onContextMenu: PopupUtils.open(contextualOptionsComponent, tabDelegate, {"targetIndex": index})

    property Component faviconFactory: Component {
        FaviconFetcher {

        }
    }

    function iconSourceFromModelItem(modelData, index) {
        var incubator = faviconFactory.incubateObject(
            parent,
            {
                "shouldCache": Qt.binding(function() { return !incognito; }),
                "url": Qt.binding(function() { return modelData.icon || ""; })
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

    Component {
        id: contextualOptionsComponent
        ActionSelectionPopover {
            id: menu
            objectName: "tabContextualActions"
            property int targetIndex
            readonly property var tab: tabsBar.model.get(targetIndex)

            actions: ActionList {
                Action {
                    objectName: "tab_action_new_tab"
                    text: i18n.tr("New Tab")
                    onTriggered: tabsBar.requestNewTab(menu.targetIndex + 1, false)
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
                        tabsBar.requestNewWindowFromTab(menu.tab, function() { tabsBar.tabClosed(menu.targetIndex, true); });
                    }
                }
                Action {
                    objectName: "tab_action_close_tab"
                    text: i18n.tr("Close Tab")
                    onTriggered: tabsBar.tabClosed(menu.targetIndex, false)
                }
            }
        }
    }
}