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

    Rectangle {

        anchors.fill: parent

        Rectangle {
            color: "white"
            anchors.fill: parent
        }

        FocusScope {
            focus: true

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

                ChromeButton {
                    id: closeButton

                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }

                    iconName: "close"
                    iconSize: 0.8 * height

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
                    iconSize: 0.8 * height
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

                function isSameDomainUrl() {
                    return true
                }

                function navigationRequestedDelegate(request) {
                    var url = request.url.toString()

                    if (isSameDomainUrl(url)) {
                        request.action = Oxide.NavigationRequest.ActionReject
                    }

                    // If we are to browse in the popup to a place where we are not allows
                    if ( ! isNewForegroundWebViewDisposition(request.disposition) &&
                            ! webview.shouldAllowNavigationTo(url)) {
                        request.action = Oxide.NavigationRequest.ActionReject
                        openUrlExternally(url);
                        popup.close()
                        return;
                    }
                    // Fallback to regulat checks (there is a bit of overlap)
                    webview.navigationRequestedDelegate(request)
                }

                onNewViewRequested: popupWindowController.createPopupWindow(request)

                // Oxide (and Chromium) does not inform of non user
                // driven navigations (or more specifically redirects that
                // would be part of an popup/webview load (after its been
                // granted). Quite a few sites (e.g. Youtube),
                // create popups when clicking on links (or following a window.open())
                // with proper youtube.com address but w/ redirection
                // params, e.g.:
                // http://www.youtube.com/redirect?q=http%3A%2F%2Fgodzillamovie.com%2F&redir_token=b8WPI1pq9FHXeHm2bN3KVLAJSfp8MTM5NzI2NDg3NEAxMzk3MTc4NDc0
                // In this instance the popup & navigation is granted, but then
                // a redirect happens inside the popup to the real target url (here http://godzillamovie.com)
                // which is not trapped by a navigation requested and therefore not filtered.
                // The only way to do it atm is to listen to url changed in popups & also
                // filter there.
                onUrlChanged: {
        console.log('url ' + url)
                    var _url = url.toString();
                    if (_url.trim().length === 0)
                        return;

                    if (_url != 'about:blank' && ! webview.shouldAllowNavigationTo(_url)) {
        //                openUrlExternally(_url);
        //                popup.close()
                    }
                }
            }
            Component.onCompleted: {
                console.log('completed')
        //        popup.show()
            }
        }
    }
}
