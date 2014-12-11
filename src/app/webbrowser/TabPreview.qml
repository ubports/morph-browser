/*
 * Copyright 2014 Canonical Ltd.
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

    property alias title: label.text
    property var tab
    readonly property url url: tab ? tab.url : ""

    signal selected()
    signal closeRequested()

    Item {
        id: header

        width: parent.width
        height: units.gu(4)

        Row {
            anchors.fill: parent

            AbstractButton {
                id: closeButton
                objectName: "closeButton"

                height: parent.height
                width: units.gu(5)

                Rectangle {
                    anchors.fill: parent
                }

                Icon {
                    height: units.gu(2)
                    width: height
                    anchors.centerIn: parent
                    name: "close"
                }

                onTriggered: tabPreview.closeRequested()

                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        right: parent.right
                    }
                    width: units.dp(1)

                    color: "#d9d9d9"
                }
            }

            Item {
                width: parent.width - closeButton.width
                height: parent.height

                Image {
                    id: tabBackgroundLeft
                    height: parent.height
                    anchors {
                        left: parent.left
                        right: tabBackgroundCenter.left
                    }
                    source: "assets/tab-header-left.png"
                    fillMode: Image.TileHorizontally
                }

                Image {
                    id: tabBackgroundCenter
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "assets/tab-header-center.png"
                    fillMode: Image.PreserveAspectFit
                }

                Image {
                    id: tabBackgroundRight
                    height: parent.height
                    anchors {
                        left: tabBackgroundCenter.right
                        right: parent.right
                    }
                    source: "assets/tab-header-right.png"
                    fillMode: Image.TileHorizontally
                }

                Label {
                    id: label
                    anchors {
                        fill: tabBackgroundLeft
                        leftMargin: units.gu(1)
                    }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    width: parent.width / 2

                    onClicked: tabPreview.selected()
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)

            color: "#d9d9d9"
        }
    }

    Rectangle {
        width: parent.width
        height: parent.height - header.height

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
