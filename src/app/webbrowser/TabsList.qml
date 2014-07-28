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
import Ubuntu.Components.ListItems 0.1 as ListItem

Column {
    id: tabsList

    property alias tabsModel: listview.model
    property QtObject bookmarksModel

    signal newTabClicked()
    signal switchToTabClicked(int index)
    signal tabRemoved(int index)

    spacing: units.gu(2)

    ListItem.Header {
        // TRANSLATORS: %1 refers to the number of open tabs
        text: i18n.tr("Currently viewing (%1)").arg('<font color="%1">%2</font>'.arg(UbuntuColors.orange).arg(tabsModel.count))
    }

    ListView {
        id: listview
        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        height: units.gu(17)
        spacing: units.gu(2)
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: model.currentIndex

        states: State {
            name: "close"
        }

        header: Item {
            width: units.gu(14)
            height: parent.height

            UbuntuShape {
                objectName: "newTabDelegate"
                width: units.gu(12)
                height: units.gu(12)
                color: "white"
                Label {
                    anchors.centerIn: parent
                    fontSize: "x-large"
                    text: i18n.tr("+")
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: newTabClicked()
                }
            }
        }

        delegate: PageDelegate {
            objectName: "openTabDelegate"

            width: units.gu(12)
            height: units.gu(15)

            url: model.url
            label: model.title ? model.title : model.url
            icon: model.icon
            //thumbnail: model.webview.thumbnail
            canClose: true

            state: listview.state
            onStateChanged: listview.state = state
            Connections {
                target: listview
                onStateChanged: state = listview.state
            }

            canBookmark: url.toString() && (state === "")
            bookmarksModel: tabsList.bookmarksModel

            onClicked: {
                if (state === "close") {
                    tabRemoved(index)
                } else {
                    switchToTabClicked(index)
                }
            }
        }

        onVisibleChanged: {
            if (!visible) {
                state = ""
            }
        }
    }

    function centerViewOnCurrentTab() {
        listview.positionViewAtIndex(tabsModel.currentIndex, ListView.Center)
    }
}
