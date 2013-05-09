/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1

Item {
    id: chrome

    property alias url: addressBar.url
    signal urlValidated(url url)
    property alias loading: addressBar.loading
    property alias loadProgress: progressBar.value
    property alias canGoBack: backButton.enabled
    signal goBackClicked()
    property alias canGoForward: forwardButton.enabled
    signal goForwardClicked()
    signal requestReload()
    signal requestStop()

    Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: 0.95
    }

    Row {
        id: buttons

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            margins: units.gu(1)
        }
        spacing: units.gu(1)
        clip: true

        // XXX: we should use Screen.orientation, once orientation changes are properly notified
        width: ((Screen.width < Screen.height) && addressBar.activeFocus) ? 0 : units.gu(12)
        Behavior on width {
            NumberAnimation { duration: 200 }
        }

        ChromeButton {
            id: backButton
            objectName: "backButton"
            width: units.gu(5)
            height: width
            icon: "assets/go-previous.png"
            label: "Back"
            onClicked: chrome.goBackClicked()
        }

        ChromeButton {
            id: forwardButton
            objectName: "forwardButton"
            width: units.gu(5)
            height: width
            icon: "assets/go-next.png"
            label: "Forward"
            onClicked: chrome.goForwardClicked()
        }
    }

    AddressBar {
        id: addressBar
        objectName: "addressBar"

        anchors.left: buttons.right
        anchors.right: parent.right
        anchors.rightMargin: units.gu(1)
        anchors.verticalCenter: parent.verticalCenter
        height: units.gu(5)

        onValidated: chrome.urlValidated(url)
        onRequestReload: chrome.requestReload()
        onRequestStop: chrome.requestStop()
    }

    EmbeddedProgressBar {
        id: progressBar
        visible: chrome.loading
        source: visible ? addressBar : null
        minimumValue: 0
        maximumValue: 100
        bgColor: "#DD4814" // Ubuntu orange
        fgColor: "white"
    }

    Suggestions {
        id: suggestions
        visible: addressBar.activeFocus && (count > 0)
        anchors {
            bottom: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        width: parent.width - units.gu(5)
        height: Math.min(contentHeight, units.gu(40))
        onSelected: chrome.urlValidated(url)
    }

    Image {
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        fillMode: Image.TileHorizontally
        source: "assets/toolbar_dropshadow.png"
    }
}
