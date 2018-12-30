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
import Ubuntu.Components.Extras 0.3 as Extras
import Ubuntu.Components.Popups 1.3
import "."
import ".."

Extras.TabsBar {
    id: tabsBar
    actionColor: incognito ? theme.palette.normal.background : theme.palette.normal.backgroundText
    color: incognito ? theme.palette.normal.backgroundSecondaryText : theme.palette.normal.base  // FIXME: not in palette hardcode for now
    backgroundColor: incognito ? theme.palette.normal.overlayText : theme.palette.normal.background  // FIXME: not in palette hardcode for now
    foregroundColor: incognito ? theme.palette.normal.background : theme.palette.normal.backgroundText
    dragAndDrop {
        enabled: __platformName != "ubuntumirclient"
        maxYDiff: height / 12
        mimeType: "webbrowser/tab-" + (incognito ? "incognito" : "public")
        previewUrlFromIndex: function(index) {
            if (tabsBar.model.get(index)) {
                return PreviewManager.previewPathFromUrl(tabsBar.model.get(index).url)
            } else {
                return "";
            }
        }
    }
    fallbackIcon: "stock_website"
    windowFactoryProperties: {
        "incognito": tabsBar.incognito,
        "height": window.height,
        "width": window.width,
    }

    property bool incognito

    signal requestNewTab(int index, bool makeCurrent)
    signal tabClosed(int index, bool moving)

    onContextMenu: PopupUtils.open(contextualOptionsComponent, tabDelegate, {"targetIndex": index})

    // Note: This works as a binding, when the returned value changes, QML recalls the function
    function iconSourceFromModelItem(modelData, index) {
        return modelData.tab ? modelData.tab.localIcon : "";
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
                    onTriggered: tabsBar.requestNewTab(menu.targetIndex + 1, true)
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
                        // Create new window and add existing tab
                        var window = tabsBar.windowFactory.createObject(null, windowFactoryProperties);
                        window.model.addExistingTab(menu.tab);
                        window.model.selectTab(window.model.count - 1);
                        window.show();

                        // Just remove from model and do not destroy
                        // as webview is used in other window
                        tabsBar.model.removeTabWithoutDestroying(menu.targetIndex);
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
