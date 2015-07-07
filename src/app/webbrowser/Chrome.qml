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

import QtQuick 2.0
import Ubuntu.Components 1.1
import ".."

ChromeBase {
    id: chrome

    property var tabsModel
    property alias searchUrl: navigationBar.searchUrl
    property alias text: navigationBar.text
    property alias bookmarked: navigationBar.bookmarked
    property alias drawerActions: navigationBar.drawerActions
    property alias drawerOpen: navigationBar.drawerOpen
    property alias requestedUrl: navigationBar.requestedUrl
    property alias canSimplifyText: navigationBar.canSimplifyText
    property alias editing: navigationBar.editing
    property alias incognito: navigationBar.incognito
    property alias showTabsBar: tabsBar.active
    property alias showFaviconInAddressBar: navigationBar.showFaviconInAddressBar
    readonly property alias bookmarkTogglePlaceHolder: navigationBar.bookmarkTogglePlaceHolder

    signal requestNewTab()

    backgroundColor: incognito ? UbuntuColors.darkGrey : Theme.palette.normal.background

    implicitHeight: tabsBar.height + navigationBar.height

    function selectAll() {
        navigationBar.selectAll()
    }

    FocusScope {
        anchors.fill: parent

        focus: true

        Loader {
            id: tabsBar

            sourceComponent: TabsBar {
                model: tabsModel
                incognito: chrome.incognito
                onRequestNewTab: chrome.requestNewTab()
            }

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: active ? units.gu(4) : 0
        }

        Rectangle {
            anchors.fill: navigationBar
            color: "#dedede"
        }

        NavigationBar {
            id: navigationBar

            webview: chrome.webview

            focus: true

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: units.gu(6)
        }
    }
}
