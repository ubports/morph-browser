/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import ".."

ChromeBase {
    id: chrome

    property var webview: null
    property bool navigationButtonsVisible: false
    property bool accountSwitcher: false
    property real availableHeight
    signal toggleDownloads()
    property bool showDownloadButton: false
    property bool downloadNotify: false
    readonly property alias downloadsButtonPlaceHolder: downloadsButton

    loading: webview && webview.loading && webview.loadProgress !== 100
    loadProgress: loading ? webview.loadProgress : 0

    function updateChromeElementsColor(color) {
        chromeTextLabel.color = color;

        backButton.iconColor = color;
        forwardButton.iconColor = color;

        reloadButton.iconColor = color;
        settingsButton.iconColor = color;
        accountsButton.iconColor = color;

        downloadsButton.iconColor = Qt.binding(function(){ return downloadNotify ? theme.palette.normal.focus : color})
    }

    function showNavHistory(model, caller) {
        navHistPopup.model = model
        navHistPopup.show(caller)
    }

    signal chooseAccount()

    NavHistoryPopup {
        id: navHistPopup

        availHeight: chrome.availableHeight
        availWidth: chrome.width
        onNavigate: {
            chrome.webview.goBackOrForward(offset)
        }
    }

    FocusScope {
        anchors {
            fill: parent
            margins: units.gu(1)
        }

        focus: true

        ChromeButton {
            id: backButton
            objectName: "backButton"

            iconName: "previous"
            iconSize: 0.6 * height

            height: parent.height
            visible: chrome.navigationButtonsVisible
            width: visible ? height : 0

            enableContextMenu: true
            contextMenu: navHistPopup

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoBack : false
            onTriggered: {
                if (chrome.webview.loading) {
                    chrome.webview.stop()
                }
                chrome.webview.goBack()
            }

            onShowContextMenu: showNavHistory(chrome.webview.navigationHistory.backItems, backButton)
        }

        ChromeButton {
            id: forwardButton
            objectName: "forwardButton"

            iconName: "next"
            iconSize: 0.6 * height

            height: parent.height
            visible: chrome.navigationButtonsVisible && enabled
            width: visible ? height : 0

            enableContextMenu: true
            contextMenu: navHistPopup

            anchors {
                left: backButton.right
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview ? chrome.webview.canGoForward : false
            onTriggered: {
                if (chrome.webview.loading) {
                    chrome.webview.stop()
                }
                chrome.webview.goForward()
            }

            onShowContextMenu: showNavHistory(chrome.webview.navigationHistory.forwardItems, forwardButton)
        }

        Item {
            id: faviconContainer

            height: parent.height
            width: height
            anchors.left: forwardButton.right

            Favicon {
                anchors.centerIn: parent
                source: chrome.webview ? chrome.webview.icon : null
            }
        }

        Label {
            id: chromeTextLabel
            objectName: "chromeTextLabel"

            anchors {
                left: faviconContainer.right
                right: reloadButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }

            text: chrome.webview.title ? chrome.webview.title : chrome.webview.url
            elide: Text.ElideRight
        }

        ChromeButton {
            id: reloadButton
            objectName: "reloadButton"

            iconName: "reload"
            iconSize: 0.6 * height

            height: parent.height
            visible: chrome.navigationButtonsVisible
            width: visible ? height : 0

            anchors {
                right: downloadsButton.left
                verticalCenter: parent.verticalCenter
            }

            enabled: chrome.webview.url && chrome.webview.url !== ""
            onTriggered: chrome.webview.reload()
        }

        ChromeButton {
            id: downloadsButton
            objectName: "downloadsButton"

            visible: chrome.navigationButtonsVisible && showDownloadButton
            iconName: "save"
            iconSize: 0.6 * height

            height: parent.height
            width: visible ? height : 0

            anchors {
                right: settingsButton.left
                verticalCenter: parent.verticalCenter
            }

            Connections {
                target: root

                onDownloadNotifyChanged: {
                    if (downloadNotify) {
                        shakeAnimation.start()
                    }
                }
            }

            Behavior on iconColor {
                ColorAnimation { duration: UbuntuAnimation.BriskDuration  }
            }

            SequentialAnimation {
                id: shakeAnimation

                loops: 4

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Counterclockwise
                    to: 350
                    duration: 50
                }

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Clockwise
                    to: 10
                    duration: 50
                }

                RotationAnimation {
                    target: downloadsButton
                    direction: RotationAnimation.Counterclockwise
                    to: 0
                    duration: 50
                }
            }

            onTriggered: {
                toggleDownloads()
            }
        }

        ChromeButton {
            id: settingsButton
            objectName: "settingsButton"

            iconName: "settings"
            iconSize: 0.6 * height

            height: parent.height
            visible: chrome.navigationButtonsVisible
            width: visible ? height : 0

            anchors {
                right: accountsButton.left
                verticalCenter: parent.verticalCenter
            }

            onTriggered: webapp.showWebappSettings()
        }

        ChromeButton {
            id: accountsButton
            objectName: "accountsButton"

            iconName: "contact"
            iconSize: 0.6 * height

            height: parent.height
            width: visible ? height : 0

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            visible: accountSwitcher
            onTriggered: chrome.chooseAccount()
        }
    }
}
