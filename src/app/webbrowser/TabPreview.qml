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

    // The first preview in the tabs list is a special case.
    // Since it’s the current tab, instead of displaying a
    // capture, the webview below it is displayed.
    property bool showContent: true

    signal selected()
    signal closed()

    Item {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: chrome.height

        Rectangle {
            visible: !showContent
            anchors.fill: parent
            color: "#312f2c"
        }

        TabChrome {
            id: chrome

            anchors {
                left: parent.left
                right: parent.right
            }

            onSelected: tabPreview.selected()
            onClosed: tabPreview.closed()
        }
    }

    Item {
        width: parent.width
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: "white"
            visible: showContent && !previewContainer.visible
        }

        Image {
            visible: showContent && !previewContainer.visible
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

        Label {
            visible: showContent && !previewContainer.visible
            text: i18n.tr("Tap to view")
            anchors {
                centerIn: parent
                verticalCenterOffset: units.gu(-2)
            }
        }

        Image {
            id: previewContainer
            visible: showContent && source.toString() && (status == Image.Ready)
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
            objectName: "selectArea"
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons

            // 'clicked' events are emitted even if the cursor has been dragged
            // (http://doc.qt.io/qt-5/qml-qtquick-mousearea.html#clicked-signal),
            // but we don’t want a drag gesture to select the tab (when e.g. the
            // user has reached the top/bottom of the tabs view and starts another
            // gesture to drag further beyond the boundaries of the view).
            property point pos
            onPressed: {
                if (mouse.button == Qt.LeftButton) {
                    pos = Qt.point(mouse.x, mouse.y)
                }
            }
            onReleased: {
                if (mouse.button == Qt.LeftButton) {
                    var d = Math.sqrt(Math.pow(mouse.x - pos.x, 2) + Math.pow(mouse.y - pos.y, 2))
                    if (d < units.gu(1)) {
                        tabPreview.selected()
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop { position: 0.0; color: "white" }
                GradientStop { position: 1.0; color: "black" }
            }

            opacity: 0.4
        }
    }
}
