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
import Ubuntu.WebContainer.Components 0.1

import ".."

Window {
    id: root

    property alias developerExtrasEnabled: browser.developerExtrasEnabled

    property alias backForwardButtonsVisible: browser.backForwardButtonsVisible
    property alias addressBarVisible: browser.addressBarVisible

    property string applicationName: ""
    property string url: ""
    property alias webappName: browser.webappName
    property alias webappModelSearchPath: browser.webappModelSearchPath
    property alias webappUrlPatterns: browser.webappUrlPatterns

    property string accountProvider: ""

    contentOrientation: browser.screenOrientation

    width: 800
    height: 600

    title: {
        if (typeof(webappName) === 'string' && webappName.length !== 0) {
            return webappName
        } else if (browser.title) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Application").arg(browser.title)
        } else {
            return i18n.tr("Ubuntu Web Application")
        }
    }

    PageStack {
        id: stack

        Page {
            id: webappPage

            visible: false
            anchors.fill: parent

            WebApp {
                id: browser

                anchors.fill: parent

                property int screenOrientation: Screen.orientation

                chromeless: !backForwardButtonsVisible && !addressBarVisible
                webbrowserWindow: webbrowserWindowProxy

                Component.onCompleted: i18n.domain = "webbrowser-app"
            }
        }

        Page {
            id: accountsPage

            visible: false
            anchors.fill: parent

            AccountsLoginPage {
                id: accountsLogin

                anchors.fill: parent

                accountProvider: root.accountProvider
                applicationName: applicationName

                QtObject {
                    id: internal
                    function onMoved (result) {
                        webappCookieStore.moved.disconnect(internal.onMoved);
                        if (! result) {
                            console.log("Unable to move cookies");
                        }
                        advanceToWebappStep();
                    }
                }

                onDone: {
                    if ( ! accountsPage.visible)
                        return;
                    if ( ! credentialsId) {
                        advanceToWebappStep();
                        return;
                    }
                    var instance = onlineAccountStoreComponent.createObject(accountsLogin, {accountId: credentialsId});

                    webappCookieStore.moved.connect(internal.onMoved)
                    webappCookieStore.moveFrom(instance);
                }
            }
        }
    }

    SqliteCookieStore {
        id: webappCookieStore
        dbPath: ".local/share/" + applicationName + "/.QtWebKit/cookies.db"
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }

    onAccountProviderChanged: {
        if (accountProvider.length !== 0) {
            accountsLogin.accountProvider = accountProvider
            stack.push(accountsPage);
        }
        else {
            advanceToWebappStep();
        }
    }

    function advanceToWebappStep() {
        // when calling the container w/ a names webapp param,
        //  (e.g. --webapp=facebook), the webview is automagically
        //  set up to browse to the 'homepage' param specified in the
        //  webapp manifest.json file so it doesn't need to be set.
        if (url && url.length !== 0)
            browser.url = url;
        stack.push(webappPage);
    }
}


