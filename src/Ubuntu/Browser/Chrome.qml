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

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: 0.95
    }

    ChromeButton {
        id: backButton
        objectName: "backButton"
        anchors.left: parent.left
        anchors.margins: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        width: units.gu(5)
        height: width
        icon: "assets/icon_back.png"
        onClicked: chrome.goBackClicked()
    }

    AddressBar {
        id: addressBar
        objectName: "addressBar"

        anchors.left: backButton.right
        anchors.right: forwardButton.left
        anchors.margins: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        height: units.gu(5)

        onValidated: chrome.urlValidated(url)
    }

    ChromeButton {
        id: forwardButton
        objectName: "forwardButton"
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        width: units.gu(5)
        height: width
        icon: "assets/icon_forward.png"
        onClicked: chrome.goForwardClicked()
    }

    Image {
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fillMode: Image.TileHorizontally
        source: "assets/toolbar_dropshadow.png"
    }
}
