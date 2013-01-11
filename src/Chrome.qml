/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of kalossi-browser.
 *
 * kalossi-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * kalossi-browser is distributed in the hope that it will be useful,
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

    property alias url: addressBar.text
    signal urlValidated(url url)
    property alias canGoBack: backButton.enabled
    signal goBackClicked
    property alias canGoForward: forwardButton.enabled
    signal goForwardClicked
    signal reloadClicked

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
        spacing: units.gu(2)

        Button {
            id: backButton
            text: "⊲"
            width: units.gu(6)
            onClicked: chrome.goBackClicked()
        }
        Button {
            id: forwardButton
            text: "⊳"
            width: units.gu(6)
            onClicked: chrome.goForwardClicked()
        }
        Button {
            id: bookmarkButton
            text: "✩"
            width: units.gu(6)
        }
        Button {
            id: refreshButton
            text: "↻"
            width: units.gu(6)
            onClicked: chrome.reloadClicked()
        }
    }

    TextField {
        id: addressBar

        anchors.left: buttons.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: units.gu(2)

        onAccepted: chrome.urlValidated(text)
    }
}
