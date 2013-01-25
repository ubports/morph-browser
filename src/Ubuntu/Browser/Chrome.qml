/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
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
    id: chrome

    property alias url: addressBar.url
    signal urlValidated(url url)
    property alias canGoBack: backButton.enabled
    signal goBackClicked
    property alias canGoForward: forwardButton.enabled
    signal goForwardClicked
    signal reloadClicked
    property alias loading: loading.running

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: 0.9
    }

    MouseArea {
        // Intercept mouse clicks that go through disabled buttons,
        // to avoid forwarding them to the web page below.
        anchors.fill: parent
    }

    Row {
        id: buttons

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: units.gu(2)
        spacing: units.gu(1)

        Button {
            id: backButton
            text: "⊲"
            width: units.gu(5)
            onClicked: chrome.goBackClicked()
        }
        Button {
            id: forwardButton
            text: "⊳"
            width: units.gu(5)
            onClicked: chrome.goForwardClicked()
        }
        Button {
            id: refreshButton
            text: "↻"
            width: units.gu(5)
            onClicked: chrome.reloadClicked()
        }
    }

    AddressBar {
        id: addressBar
        objectName: "addressBar"

        anchors.left: buttons.right
        anchors.right: loading.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(2)

        onValidated: chrome.urlValidated(url)
    }

    ActivityIndicator {
        id: loading
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: units.gu(3)
    }
}
