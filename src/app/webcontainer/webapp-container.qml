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
import Ubuntu.Components 1.1
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Ubuntu.Web 0.2
import webcontainer.private 0.1
import ".."

BrowserWindow {
    id: root
    objectName: "webappContainer"

    property bool backForwardButtonsVisible: true
    property bool chromeVisible: true

    property string localCookieStoreDbPath: ""

    property var intentFilterHandler
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

    currentWebview: webappViewLoader.item ? webappViewLoader.item.currentWebview : null

    property bool runningLocalApplication: false

    title: getWindowTitle()

    // Used for testing
    signal intentUriHandleResult(string uri)

    function getWindowTitle() {
        var webappViewTitle =
                webappViewLoader.item
                ? webappViewLoader.item.title : ""
        var name = getWebappName()
        if (typeof(name) === 'string' && name.length !== 0) {
            return name
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

            localUserAgentOverride: getLocalUserAgentOverrideIfAny()

            runningLocalApplication: root.runningLocalApplication
            webviewOverrideFile: root.webviewOverrideFile

            anchors.fill: parent

            webbrowserWindow: webbrowserWindowProxy

            onWebappNameChanged: {
                if (root.webappName !== browser.webappName) {
                    root.webappName = browser.webappName;
                    root.title = getWindowTitle();
                }
            }
        }
    }

    function getWebappName() {
        /**
          Any webapp name coming from the command line takes over.
          A webapp can also be defined by a specific drop-in webapp-properties.json
          file that can bundle a few specific 'properties' (as the name implies)
          instead of having them listed in the command line.
          */
        if (webappName)
            return webappName
        return webappModelSearchPath && webappModel.providesSingleInlineWebapp()
            ? webappModel.getSingleInlineWebappName()
            : ""
    }

    function getLocalUserAgentOverrideIfAny() {
        if (localUserAgentOverride.length !== 0)
            return localUserAgentOverride

        var name = getWebappName()
        if (name && webappModel.exists(name))
            return webappModel.userAgentOverrideFor(name)

        return ""
    }

    UnityWebApps.UnityWebappsAppModel {
        id: webappModel
        searchPath: root.webappModelSearchPath

        onModelContentChanged: {
            var name = getWebappName()
            if (name && root.url.length === 0) {
                var idx = webappModel.getWebappIndex(name)
                root.url = webappModel.data(
                            idx, UnityWebApps.UnityWebappsAppModel.Homepage)
            }
        }
    }

    // Because of https://launchpad.net/bugs/1398046, it's important that this
    // is the first child
    Loader {
        id: webappViewLoader
        anchors.fill: parent

        property var credentialsId: null
        property var webContextSessionCookieMode: null
        property var webappDataLocation: credentialsId != null ? dataLocation + "/id-" + credentialsId : dataLocation
    }

    Loader {
        id: accountsPageComponentLoader
        anchors.fill: parent
        onStatusChanged: {
            if (status == Loader.Error) {
                // Happens on the desktop, if Ubuntu.OnlineAccounts.Client
                // can't be imported
                loadWebAppView(true)
            } else if (status == Loader.Ready) {
                item.visible = true
                initializeForAccount(item.selectedAccount)
            }
        }
    }

    function onCookiesMoved(result) {
        if (__webappCookieStore) {
            __webappCookieStore.moved.disconnect(onCookiesMoved)
        }
        if (!result) {
            console.log("Cookies were not moved")
        } else {
            console.log("cookies moved")
        }
        webappViewLoader.item.url = root.url
    }

    function moveCookies(credentialsId) {
        console.log("moving cookies for id " + credentialsId)
        var storeComponent = localCookieStoreDbPath.length !== 0 ?
                    localCookieStoreComponent : onlineAccountStoreComponent

        var instance = storeComponent.createObject(root, { "accountId": credentialsId })
        __webappCookieStore.moved.connect(onCookiesMoved)
        __webappCookieStore.moveFrom(instance)
    }

    function doLogin() {
        if (!__webappCookieStore) {
            var context = webappViewLoader.item.currentWebview.context
            __webappCookieStore = oxideCookieStoreComponent.createObject(this, {
                "oxideStoreBackend": context.cookieManager,
                "dbPath": context.dataPath + "/cookies.sqlite"
            })
        }

        var forceCookieRefresh = false
        /* TODO: when needed, set the "forceCookieRefresh" flag so that Online
         * Accounts will use an interactive login (and hopefully get new
         * cookies). */
        console.log("Preparing for login, forced = " + forceCookieRefresh)
        accountsPageComponentLoader.item.login(forceCookieRefresh)
    }

    function initializeForAccount(credentialsId) {
        console.log("Account selected, creds: " + credentialsId)
        if (credentialsId < 0) return

        if (credentialsId > 0) {
            webappViewLoader.loaded.connect(function () {
                if (webappViewLoader.status == Loader.Ready) {
                    doLogin()
                }
            });
            webappViewLoader.credentialsId = credentialsId
            // If we need to preserve session cookies, make sure that the
            // mode is "restored" and not "persistent", or the cookies
            // transferred from OA would be lost.
            // We check if the webContextSessionCookieMode is defined and, if so,
            // we override it in the webapp loader.
            if (typeof webContextSessionCookieMode === "string") {
                webappViewLoader.webContextSessionCookieMode = "restored"
            }
        }

        loadWebAppView(credentialsId == 0)
    }

    Connections {
        target: accountsPageComponentLoader.item
        onSelectedAccountChanged: initializeForAccount(accountsPageComponentLoader.item.selectedAccount)
        onDone: {
            console.log("Authentication done, successful = " + successful)
            if (successful) {
                moveCookies(webappViewLoader.credentialsId)
            }
            // FIXME else?
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
        i18n.domain = "webbrowser-app"

        // check if we are to display the login view
        // or directly switch to the webapp view
        if (accountProvider.length !== 0 && oxide) {
            loadLoginView();
        } else {
            loadWebAppView(true);
        }
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }

    function loadLoginView() {
        accountsPageComponentLoader.setSource("AccountsPage.qml", {
            "accountProvider": accountProvider,
            "applicationName": unversionedAppId,
        })
    }

    function loadWebAppView(startBrowsing) {
        if (accountsPageComponentLoader.item)
            accountsPageComponentLoader.item.visible = false

        if (startBrowsing) {
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
        }
        webappViewLoader.sourceComponent = webappViewComponent
    }

    function makeUrlFromIntentResult(intentFilterResult) {
        var scheme = null
        var hostname = null
        var url = root.currentWebview.url || root.url
        if (intentFilterResult.host
                && intentFilterResult.host.length !== 0) {
            hostname = intentFilterResult.host
        }
        else {
            var matchHostname = url.toString().match(/.*:\/\/([^/]*)\/.*/)
            if (matchHostname.length > 1) {
                hostname = matchHostname[1]
            }
        }
        if (intentFilterResult.scheme
                && intentFilterResult.scheme.length !== 0) {
            scheme = intentFilterResult.scheme
        }
        else {
            var matchScheme = url.toString().match(/(.*):\/\/[^/]*\/.*/)
            if (matchScheme.length > 1) {
                scheme = matchScheme[1]
            }
        }
        return scheme
                + '://'
                + hostname
                + "/"
                + (intentFilterResult.uri
                    ? intentFilterResult.uri : "")
    }

    /**
     * Identity function for non-intent URIs.
     *
     * Otherwise if the URI is an intent, tries to apply a webapp
     * local filter (or identity) and reconstruct the target URI based
     * on its result.
     */
    function handleIntentUri(uri) {
        var _uri = uri;
        if (webappIntentFilter
                && webappIntentFilter.isValidIntentUri(_uri)) {
            var result = webappIntentFilter.applyFilter(_uri)
            _uri = makeUrlFromIntentResult(result)

            console.log("Intent URI '" + uri + "' was mapped to '" + _uri + "'")
        }

        // Report the result of the intent uri filtering (if any)
        // Done for testing purposed. It is not possible at this point
        // to have AP call a slot and retrieve its result synchronously.
        intentUriHandleResult(_uri)

        return _uri
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
            if (uris.length === 0 || !root.currentWebview) {
                return;
            }
            var requestedUrl = uris[0].toString();

            if (popupRedirectionUrlPrefixPattern.length !== 0
                    && requestedUrl.match(popupRedirectionUrlPrefixPattern)) {
                return;
            }

            requestedUrl = handleIntentUri(requestedUrl);

            // Add a small guard to prevent browsing to invalid urls
            if (currentWebview
                    && currentWebview.shouldAllowNavigationTo
                    && !currentWebview.shouldAllowNavigationTo(requestedUrl)) {
                return;
            }

            root.url = requestedUrl
            root.currentWebview.url = requestedUrl
        }
    }
}
