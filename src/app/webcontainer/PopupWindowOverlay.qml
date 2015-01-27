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
import com.canonical.Oxide 1.4 as Oxide
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

        Item {
            id: controls

            height: units.gu(6)
            width: parent.width - units.gu(6)

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            Button {
                id: closeButton

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                iconName: "close"
                width: 0.6 * height

                enabled: true
                visible: true

                onTriggered: popupWindowController.onViewClosed(popup)
            }
            Button {
                id: buttonOpenInBrowser

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                iconName: "language-chooser"
                width: 0.6 * height

                enabled: true
                visible: true

                onTriggered: popupWindowController.onOpenInBrowser(popupWebview.url, popup)
            }
        }

        Oxide.WebView {
            id: popupWebview

            context: webContext

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                top: controls.bottom
            }

            onNewViewRequested: popupWindowController.createPopupView(
                                    popup.parent, request, false, context)

            onCloseRequested: {
                popupWindowController.onViewClosed(popup)
            }
        }
    }
}
