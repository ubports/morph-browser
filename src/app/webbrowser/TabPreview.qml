/*
 * Copyright 2014-2015 Canonical Ltd.
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

Column {
    id: tabPreview

    property alias title: chrome.title
    property var tab
    readonly property url url: tab ? tab.url : ""

    signal selected()
    signal closed()

    TabChrome {
        id: chrome

        anchors {
            left: parent.left
            right: parent.right
        }

        onSelected: tabPreview.selected()
        onClosed: tabPreview.closed()
    }

    Rectangle {
        width: parent.width
        height: parent.height - chrome.height

        Image {
            visible: !previewContainer.visible
            source: "assets/tab-artwork.png"
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            height: Math.min(parent.height / 1.6, units.gu(28))
            width: height
            anchors {
                right: parent.right
                rightMargin: -width / 5
                bottom: parent.bottom
                bottomMargin: -height / 10
            }
        }

        Label {
            visible: !previewContainer.visible
            text: i18n.tr("Tap to view")
            anchors {
                centerIn: parent
                verticalCenterOffset: units.gu(-2)
            }
        }

        Image {
            id: previewContainer
            visible: source.toString() && (status == Image.Ready)
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: sourceSize.height
            fillMode: Image.Pad
            source: tabPreview.tab ? tabPreview.tab.preview : ""
            asynchronous: true
            cache: false
            onStatusChanged: {
                if (status == Image.Error) {
                    // The cached preview doesn’t exist any longer
                    tabPreview.tab.preview = ""
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: tabPreview.selected()
        }

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop { position: 0.0; color: "white" }
                GradientStop { position: 1.0; color: "black" }
            }

            opacity: 0.3
        }
    }
}
