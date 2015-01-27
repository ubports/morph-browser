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
import QtQuick.Window 2.0
import Ubuntu.Web 0.2
import com.canonical.Oxide 1.0 as Oxide
import Ubuntu.Components 1.1
import ".."

Item {
    id: popup

    property var popupWindowController
    property var webContext
    property alias request: popupWebview.request

    Rectangle {
        color: "#AAAAAA"
        anchors.fill: parent
    }

    Item {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        Rectangle {
            id: controls

            height: units.gu(6)
            width: parent.width - units.gu(6)
color: "red"

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            ChromeButton {
                id: closeButton

                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    verticalCenter: parent.verticalCenter
                }

                iconName: "close"
                iconSize: 0.6 * height

                enabled: true
                visible: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: console.log('*****************************')
                }
            }
            ChromeButton {
                id: buttonOpenInBrowser

                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    verticalCenter: parent.verticalCenter
                }

                iconName: "language-chooser"
                iconSize: 0.6 * height

                enabled: true
                visible: true

                MouseArea {
                    anchors.fill: parent
                    onClicked: console.log('*****************************')
                }
            }

            Text {
                id: name
                text: qsTr("text")
                anchors {
                    left: buttonOpenInBrowser.right
                    top: parent.top
                    bottom: parent.bottom
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        WebView {
            id: popupWebview

            context: webContext

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                top: controls.bottom
            }

            onNewViewRequested: popupWindowController.createPopupView(
                                    request, false, context)
        }
    }
}
