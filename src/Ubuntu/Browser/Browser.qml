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
import QtWebKit 3.0
import Ubuntu.Components 0.1
import Ubuntu.HUD 1.0 as HUD

FocusScope {
    id: browser

    property bool chromeless: false
    property alias url: webview.url
    // title is a bound property instead of an alias because of QTBUG-29141
    property string title: webview.title
    property string desktopFileHint: ""
    property string qtwebkitdpr: "1.0"
    property bool developerExtrasEnabled: false
    // necessary so that all widgets (including popovers) follow that
    property alias automaticOrientation: orientationHelper.automaticOrientation

    focus: true

    HUD.HUD {
        id: hud
        /*
         * As an unfortunate implementation detail the applicationIdentifier is
         * a bit special property of the HUD. It can only be set once; when it's set to
         * anything else than an empty string (which happens to be the default value)
         * the application gets registered to HUD with the given identifier which can not
         * be changed afterwards.
         *
         * Therefore we need to have the special "<not set>" value to indicate that there was
         * no hint set with the command line parameter and we should register as "webbrowser-app".
         *
         * We need to have a different applicationIdentifier for the browser because of webapps.
         *
         * Webapps with desktop files are executed like this:
         *
         *     $ webbrowser-app --chromeless http://m.amazon.com --desktop_file_hint=/usr/share/applications/amazon-webapp.desktop
         *
         * It is the Shell that adds the --desktop_file_hint command line argument.
         */
        applicationIdentifier: (browser.desktopFileHint == "<not set>") ? "webbrowser-app" : browser.desktopFileHint
        HUD.Context {
            HUD.Action {
                label: i18n.tr("Goto")
                keywords: i18n.tr("Address;URL;www")
                enabled: false // TODO: parametrized action
            }
            HUD.Action {
                label: i18n.tr("Back")
                keywords: i18n.tr("Older Page")
                enabled: webview.canGoBack
                onTriggered: webview.goBack()
            }
            HUD.Action {
                label: i18n.tr("Forward")
                keywords: i18n.tr("Newer Page")
                enabled: webview.canGoForward
                onTriggered: webview.goForward()
            }
            HUD.Action {
                label: i18n.tr("Reload")
                keywords: i18n.tr("Leave Page")
                onTriggered: webview.reload()
            }
            HUD.Action {
                label: i18n.tr("Bookmark")
                keywords: i18n.tr("Add This Page to Bookmarks")
                enabled: false // TODO: implement bookmarks
            }
            HUD.Action {
                label: i18n.tr("New Tab")
                keywords: i18n.tr("Open a New Tab")
                enabled: false // TODO: implement tabs
            }
        }
    }

    onQtwebkitdprChanged: {
        // Do not make this patch to QtWebKit a hard requirement.
        if (webview.experimental.hasOwnProperty('devicePixelRatio')) {
            webview.experimental.devicePixelRatio = qtwebkitdpr
        }
    }

    OrientationHelper {
        id: orientationHelper

        UbuntuWebView {
            id: webview

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: osk.top
            }

            focus: true

            experimental.preferences.developerExtrasEnabled: browser.developerExtrasEnabled

            onUrlChanged: {
                if (!browser.chromeless) {
                    chromeLoader.item.url = url
                }
            }

            onLoadingChanged: {
                error.visible = (loadRequest.status === WebView.LoadFailedStatus)
                if (loadRequest.status === WebView.LoadSucceededStatus) {
                    historyModel.add(webview.url, webview.title, webview.icon)
                }
            }
        }

        ErrorSheet {
            id: error
            anchors.fill: webview
            visible: false
            url: webview.url
            onRefreshClicked: webview.reload()
        }

        Panel {
            id: panel

            locked: browser.chromeless

            anchors {
                left: parent.left
                right: parent.right
                bottom: opened ? osk.top : parent.bottom
            }
            height: units.gu(8)

            Loader {
                id: chromeLoader

                active: !browser.chromeless
                source: "Chrome.qml"

                anchors.fill: parent

                Binding {
                    target: chromeLoader.item
                    property: "loading"
                    value: webview.loading || (webview.loadProgress == 0)
                }

                Binding {
                    target: chromeLoader.item
                    property: "loadProgress"
                    value: webview.loadProgress
                }

                Binding {
                    target: chromeLoader.item
                    property: "canGoBack"
                    value: webview.canGoBack
                }

                Binding {
                    target: chromeLoader.item
                    property: "canGoForward"
                    value: webview.canGoForward
                }

                Connections {
                    target: chromeLoader.item
                    onGoBackClicked: webview.goBack()
                    onGoForwardClicked: webview.goForward()
                    onUrlValidated: browser.url = url
                    property bool stopped: false
                    onLoadingChanged: {
                        if (chromeLoader.item.loading) {
                            panel.opened = true
                        } else if (stopped) {
                            stopped = false
                        } else if (!chromeLoader.item.addressBar.activeFocus) {
                            panel.opened = false
                            webview.forceActiveFocus()
                        }
                    }
                    onRequestReload: webview.reload()
                    onRequestStop: {
                        stopped = true
                        webview.stop()
                    }
                }
            }
        }

        KeyboardRectangle {
            id: osk
        }
    }

    Component.onCompleted: {
        Theme.loadTheme(Qt.resolvedUrl("webbrowser-app.qmltheme"))
        i18n.domain = "webbrowser-app"
    }
}
