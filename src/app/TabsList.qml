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
    property alias model: listview.model

    signal newTabClicked()
    signal switchToTabClicked(int index)
    signal tabRemoved(int index)

    spacing: units.gu(2)

    ListItem.Header {
        // TRANSLATORS: %1 refers to the number of open tabs
        text: i18n.tr("Currently viewing (%1)").arg('<font color="%1">%2</font>'.arg(UbuntuColors.orange).arg(model.count))
    }

    ListView {
        id: listview
        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        height: units.gu(16)
        spacing: units.gu(2)
        orientation: ListView.Horizontal
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
            height: units.gu(14)

            label: model.title ? model.title : model.url
            thumbnail: model.webview.thumbnail

            Item {
                width: units.gu(5)
                height: units.gu(5)
                anchors {
                    top: parent.top
                    topMargin: -units.gu(1)
                    right: parent.right
                    rightMargin: -units.gu(1)
                }

                Image {
                    id: closeButton

                    source: "assets/close_btn.png"

                    anchors.centerIn: parent
                    width: units.gu(4)
                    height: units.gu(4)

                    states: State {
                        name: "hidden"
                        PropertyChanges {
                            target: closeButton
                            width: 0
                            height: 0
                        }
                    }
                    state: (listview.state == "close") ? "" : "hidden"

                    transitions: Transition {
                        UbuntuNumberAnimation {
                            properties: "width,height"
                        }
                    }
                }
            }


            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (listview.state == "close") {
                        tabRemoved(index)
                    } else {
                        switchToTabClicked(index)
                    }
                }
                onPressAndHold: {
                    if (listview.state == "close") {
                        listview.state = ""
                    } else {
                        listview.state = "close"
                    }
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
        listview.positionViewAtIndex(model.currentIndex, ListView.Center)
    }
}
