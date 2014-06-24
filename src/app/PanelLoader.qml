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
import Ubuntu.Components 0.1

Loader {
    id: chromePanel

    property var currentWebview
    property var panel: item ? item : null
    property Item chrome: item ? item.contents[0] : null

    property bool chromeless: false
    property bool opened: panel ? panel.opened : false

    property bool backForwardButtonsVisible: true
    property bool activityButtonVisible: true
    property bool addressBarVisible: true

    signal urlValidated
    signal toggleActivityViewClicked

    function open() {
        if (panel) {
            panel.open()
        }
    }

    function close() {
        if (panel) {
            panel.close()
        }
    }

    state: panel ? panel.state : ""

    sourceComponent: chromePanel.chromeless ? undefined : panelComponent

    Component {
        id: panelComponent

        Panel {
            id: panelItem
            anchors {
                left: parent ? parent.left : undefined
                right: parent ? parent.right : undefined
                bottom: parent ? parent.bottom : undefined
            }
            height: units.gu(8)

            locked: chromePanel.currentWebview ? chromePanel.currentWebview.fullscreen : false
            Component.onCompleted: open()
            onOpenedChanged: {
                if (!opened) {
                    Qt.inputMethod.hide()
                }
            }

            Chrome {
                id: chrome

                anchors.fill: parent
                property Panel panel: panelItem

                Connections {
                    target: chromePanel
                    onCurrentWebviewChanged: {
                        if (currentWebview !== undefined) {
                            chrome.url = currentWebview.url
                        }
                    }
                }
                Connections {
                    target: chromePanel.currentWebview
                    onUrlChanged: {
                        // ensure that the URL actually changes so that the
                        // address bar is updated in case the user has entered a
                        // new address that redirects to where she previously was
                        // (https://bugs.launchpad.net/webbrowser-app/+bug/1306615)
                        chrome.url = ""
                        chrome.url = currentWebview.url
                    }
                }

                loading: currentWebview ? currentWebview.loading
                         // workaround for https://bugs.launchpad.net/oxide/+bug/1290821
                         && !currentWebview.lastLoadStopped
                         : false
                loadProgress: currentWebview ? currentWebview.loadProgress : 0

                canGoBack: currentWebview ? currentWebview.canGoBack : false
                onGoBackClicked: currentWebview.goBack()

                canGoForward: currentWebview ? currentWebview.canGoForward : false
                onGoForwardClicked: currentWebview.goForward()

                onUrlValidated: {
                    currentWebview.url = url
                    chromePanel.urlValidated()
                }

                backForwardButtonsVisible: chromePanel.backForwardButtonsVisible
                activityButtonVisible: chromePanel.activityButtonVisible
                addressBarVisible: chromePanel.addressBarVisible

                property bool stopped: false
                onLoadingChanged: {
                    if (loading) {
                        if (panel) {
                            panel.open()
                        }
                    } else if (stopped) {
                        stopped = false
                    } else if (!addressBar.activeFocus) {
                        if (panel) {
                            panel.close()
                        }
                        if (currentWebview) {
                            currentWebview.forceActiveFocus()
                        }
                    }
                }

                onRequestReload: currentWebview.reload()
                onRequestStop: {
                    stopped = true
                    currentWebview.stop()
                }

                onToggleTabsClicked: toggleActivityViewClicked()
            }
        }
    }

    Connections {
        target: chromePanel.currentWebview
        onFullscreenChanged: {
            if (chromePanel.currentWebview.fullscreen) {
                chromePanel.close()
            }
        }
    }
}
