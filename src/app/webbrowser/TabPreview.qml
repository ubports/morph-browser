/*
 * Copyright 2014-2015 Canonical Ltd.
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
import QtQuick.Controls 2.2 as QQC2

QQC2.SwipeDelegate {
    id: tabPreview

    property alias title: chrome.title
    property alias tabIcon: chrome.icon
    property alias incognito: chrome.incognito
    property var tab
    readonly property url url: tab ? tab.url : ""

    background: Rectangle {
        color: "transparent"
    }
    padding: 0
    swipe.enabled: true
    swipe.behind: Rectangle {
        width: tabPreview.width
        height: tabPreview.height
        color: "transparent"
    }

    swipe.onCompleted: closed()
    onClicked: tabPreview.selected()

    signal selected()
    signal closed()

    contentItem: Item {

        TabChrome {
            id: chrome

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            tabWidth: units.gu(26)

            onSelected: tabPreview.selected()
            onClosed: tabPreview.closed()
        }

        Item {
            anchors {
                top: chrome.bottom
                topMargin: units.dp(-1)
                left: parent.left
                right: parent.right
            }



            visible: !tab.loadingPreview
            height: parent.height
            clip: true

            Rectangle {
                anchors.fill: parent
                color: theme.palette.normal.foreground
            }

            Image {
                visible: !previewContainer.visible
                source: "assets/tab-artwork.png"
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                width: parent.width / 5
                height: width
                anchors {
                    right: parent.right
                    rightMargin: -width / 5
                    bottom: parent.bottom
                    bottomMargin: -height / 10
                }
            }

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: units.dp(1)

                color: theme.palette.normal.base
            }

            Label {
                visible: !previewContainer.visible
                text: i18n.tr("Tap to view")
                anchors {
                    top: parent.top
                    topMargin: units.gu(12)
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Image {
                id: previewContainer
                visible: source.toString() && (status == Image.Ready)
                anchors.fill: parent
                anchors.topMargin: units.dp(1)
                verticalAlignment: Image.AlignTop
                fillMode: Image.PreserveAspectFit
                source: tabPreview.tab ? tabPreview.tab.preview : ""
                asynchronous: true
                cache: false
                onStatusChanged: {
                    if (status != Image.Loading) {
                        tab.loadingPreview = false
                    }
                }
            }
        }
    }
}
