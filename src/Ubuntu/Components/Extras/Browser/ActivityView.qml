/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1

Item {
    property alias tabsModel: tabsList.model
    property alias historyModel: historyView.model

    signal historyEntryRequested(url url)
    signal newTabRequested()
    signal switchToTabRequested(int index)
    signal closeTabRequested(int index)

    onVisibleChanged: {
        if (visible) {
            tabsList.centerViewOnCurrentTab()
        }
    }

    MouseArea {
        // Prevent mouse/touch events from propagating to the webview below.
        anchors.fill: parent
        hoverEnabled: true
        onWheel: {}
    }

    Header {
        id: header
        title: tabs.selectedTab.title
    }

    Tabs {
        id: tabs

        anchors {
            fill: undefined
            top: header.bottom
            topMargin: units.dp(-1)
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Tab {
            title: i18n.tr("Activity")

            visible: true

            Item {
                anchors.fill: parent
                opacity: 0.95

                HistoryView {
                    id: historyView

                    anchors {
                        top: parent.top
                        bottom: tabsList.top
                        left: parent.left
                        right: parent.right
                    }
                    color: "#D6CFC9"

                    onHistoryEntryClicked: historyEntryRequested(url)
                }

                TabsList {
                    id: tabsList

                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: units.gu(18)

                    onNewTabClicked: newTabRequested()
                    onSwitchToTabClicked: switchToTabRequested(index)
                    onTabRemoved: closeTabRequested(index)
                }
            }
        }
    }
}
