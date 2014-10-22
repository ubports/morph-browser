/*
 * Copyright 2013-2014 Canonical Ltd.
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
import QtQuick.Window 2.1
import Ubuntu.Components 1.1
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import webcontainer.private 0.1

Window {
    id: root
    objectName: "webappContainer"

    property bool developerExtrasEnabled: false

    property bool backForwardButtonsVisible: true
    property bool chromeVisible: true

    property string localCookieStoreDbPath: ""

    property string url: ""
    property string webappName: ""
    property string webappModelSearchPath: ""
    property var webappUrlPatterns
    property bool oxide: false
    property string accountProvider: ""
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property var __webappCookieStore: null
    property string localUserAgentOverride: ""
    property bool blockOpenExternalUrls: false

    contentOrientation: Screen.orientation

    width: 800
    height: 600

    title: getWindowTitle()

    function getWindowTitle() {
        var webappViewTitle = webappViewLoader.item ? webappViewLoader.item.title : ""
        if (typeof(webappName) === 'string' && webappName.length !== 0) {
            return webappName
        } else if (webappViewTitle) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(webappViewTitle)
        } else {
            return i18n.tr("Ubuntu Web Browser")
        }
    }

    Component {
        id: webappViewComponent

        WebApp {
            id: browser

            url: accountProvider.length !== 0 ? "" : root.url

            dataPath: webappDataLocation
            webappName: root.webappName
            chromeVisible: root.chromeVisible
            backForwardButtonsVisible: root.backForwardButtonsVisible
            developerExtrasEnabled: root.developerExtrasEnabled
            oxide: root.oxide
            webappModelSearchPath: root.webappModelSearchPath
            webappUrlPatterns: root.webappUrlPatterns
            blockOpenExternalUrls: root.blockOpenExternalUrls

            popupRedirectionUrlPrefixPattern: root.popupRedirectionUrlPrefixPattern

            localUserAgentOverride: root.localUserAgentOverride

            webviewOverrideFile: root.webviewOverrideFile

            anchors.fill: parent

            webbrowserWindow: webbrowserWindowProxy

            onWebappNameChanged: {
                if (root.webappName !== browser.webappName) {
                    root.webappName = browser.webappName;
                    root.title = getWindowTitle();
                }
            }

            Component.onCompleted: i18n.domain = "webbrowser-app"
        }
    }

    function getLocalUserAgentOverrideIfAny() {
        if (localUserAgentOverride.length !== 0)
            return localUserAgentOverride

        if (webappName && webappModel.exists(webappName))
            return webappModel.userAgentOverrideFor(webappName)

        return ""
    }

    UnityWebApps.UnityWebappsAppModel {
        id: webappModel
        searchPath: root.webappModelSearchPath

        onModelContentChanged: {
            if (root.webappName && root.url.length === 0) {
                var idx = webappModel.getWebappIndex(root.webappName)
                root.url = webappModel.data(idx, UnityWebApps.UnityWebappsAppModel.Homepage)
            }
        }
    }

    visibility: webappViewLoader.item &&
                webappViewLoader.item.currentWebview &&
                webappViewLoader.item.currentWebview.fullscreen ? Window.FullScreen : Window.AutomaticVisibility

    Loader {
        id: accountsPageComponentLoader
        anchors.fill: parent
        onStatusChanged: {
            if (status == Loader.Error) {
                // Happens on the desktop, if Ubuntu.OnlineAccounts.Client
                // can't be imported
                loadWebAppView()
            } else if (status == Loader.Ready) {
                item.visible = true
            }
        }
    }

    Loader {
        id: webappViewLoader
        anchors.fill: parent

        property var credentialsId: null
        property var webappDataLocation: credentialsId != null ? dataLocation + "/id-" + credentialsId : dataLocation
    }

    function onCookiesMoved(result) {
        if (__webappCookieStore) {
            __webappCookieStore.moved.disconnect(onCookiesMoved)
        }
        if (!result) {
            console.log("Cookies were not moved")
        }
        webappViewLoader.item.url = root.url
    }

    function moveCookies(credentialsId) {
        if (!__webappCookieStore) {
            var context = webappViewLoader.item.currentWebview.context
            __webappCookieStore = oxideCookieStoreComponent.createObject(this, {
                "oxideStoreBackend": context.cookieManager,
                "dbPath": context.dataPath + "/cookies.sqlite"
            })
        }

        var storeComponent = localCookieStoreDbPath.length !== 0 ?
                    localCookieStoreComponent : onlineAccountStoreComponent

        var instance = storeComponent.createObject(root, { "accountId": credentialsId })
        __webappCookieStore.moved.connect(onCookiesMoved)
        __webappCookieStore.moveFrom(instance)
    }

    Connections {
        target: accountsPageComponentLoader.item
        onDone: {
            if (successful && credentialsId) {
                webappViewLoader.loaded.connect(function () {
                    if (webappViewLoader.status == Loader.Ready) {
                        moveCookies(webappViewLoader.credentialsId)
                    }
                });
                webappViewLoader.credentialsId = credentialsId
                webappViewLoader.sourceComponent = webappViewComponent
            }
            else {
                loadWebAppView()
            }
        }
    }

    Component {
        id: oxideCookieStoreComponent
        ChromeCookieStore {
        }
    }

    Component {
        id: localCookieStoreComponent
        LocalCookieStore {
            dbPath: localCookieStoreDbPath
        }
    }

    Component.onCompleted: {
        updateCurrentView()
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }

    function updateCurrentView() {
        // check if we are to display the login view
        // or directly switch to the webapp view
        if (accountProvider.length !== 0 && oxide) {
            loadLoginView();
        } else {
            loadWebAppView();
        }
    }

    function loadLoginView() {
        accountsPageComponentLoader.setSource("AccountsPage.qml", {
            "accountProvider": accountProvider,
            "applicationName": unversionedAppId,
        })
    }

    function loadWebAppView() {
        if (accountsPageComponentLoader.item)
            accountsPageComponentLoader.item.visible = false

        webappViewLoader.loaded.connect(function () {
            if (webappViewLoader.status === Loader.Ready) {
                // As we use StateSaver to restore the URL, we need to check first if
                // it has not been set previously before setting the URL to the default property 
                // homepage.
                var webView = webappViewLoader.item.currentWebview
                var current_url = webView.url.toString();
                if (!current_url || current_url.length === 0) {
                    webView.url = root.url
                }
            }
        });
        webappViewLoader.sourceComponent = webappViewComponent
    }

    function updateBrowserUrl(url) {
        root.url = url;
        if (browser.currentWebview) {
            browser.currentWebview.url = url;
        }
    }

    // Handle runtime requests to open urls as defined
    // by the freedesktop application dbus interface's open
    // method for DBUS application activation:
    // http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#dbus
    // The dispatch on the org.freedesktop.Application if is done per appId at the
    // url-dispatcher/upstart level.
    Connections {
        target: UriHandler
        onOpened: {
            // only consider the first one (if multiple)
            if (uris.length === 0 || !browser.currentWebview) {
                return;
            }
            var requestedUrl = uris[0].toString();

            if (popupRedirectionUrlPrefixPattern.length !== 0
                    && requestedUrl.match(popupRedirectionUrlPrefixPattern)) {
                return;
            }
            updateBrowserUrl(requestedUrl);
        }
    }
}

