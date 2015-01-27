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

    visible: true

    Item {

        anchors.fill: parent

        Rectangle {
            color: "#ADADAD"
            anchors.fill: parent
        }

        Item {
            anchors {
                fill: parent
                margins: units.gu(1)
            }

            enabled: true
            visible: true

            Item {
                id: controls

                height: units.gu(6)
                width: parent.width - units.gu(6)

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }

                enabled: true
                visible: true

                ChromeButton {
                    id: closeButton

                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }

                    iconName: "close"
                    iconSize: 0.6 * height

                    enabled: true
                    visible: true

                    onTriggered: console.log('*****************************')
                    onClicked: console.log('*****************************')
                }
                ChromeButton {
                    id: buttonOpenInBrowser

                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }

                    iconName: "language-chooser"
                    iconSize: 0.6 * height

                    enabled: true
                    visible: true

                    onTriggered: console.log('*****************************')
                    onClicked: console.log('*****************************')
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
}
