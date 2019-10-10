/*
 * Copyright 2013-2017 Canonical Ltd.
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
import Qt.labs.settings 1.0
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import QtWebEngine 1.7
import Morph.Web 0.1
import webcontainer.private 0.1
import webbrowsercommon.private 0.1
import ".."

BrowserWindow {
    id: root
    objectName: "webappContainer"

    property bool backForwardButtonsVisible: true
    property bool chromeVisible: true

    property string localCookieStoreDbPath: ""

    property string url: ""
    property url webappIcon: ""
    property string webappName: ""
    property string webappModelSearchPath: ""
    property var webappUrlPatterns
    property string accountProvider: ""
    property bool accountSwitcher: false
    property string popupRedirectionUrlPrefixPattern: ""
    property url webviewOverrideFile: ""
    property var __webappCookieStore: null
    property alias webContextSessionCookieMode: webappViewLoader.webContextSessionCookieMode
    property string localUserAgentOverride: ""
    property bool blockOpenExternalUrls: false
    property bool openExternalUrlInOverlay: false
    property string defaultVideoCaptureCameraPosition: ""
    property bool popupBlockerEnabled: true
    property bool localContentCanAccessRemoteUrls: false

    currentWebview: webappViewLoader.item ? webappViewLoader.item.currentWebview : null

    property bool runningLocalApplication: false

    property bool startMaximized: false

    title: getWindowTitle()

    // Used for testing
    signal schemeUriHandleFilterResult(string uri)

    function getWindowTitle() {
        var webappViewTitle =
                webappViewLoader.item
                ? webappViewLoader.item.title : ""
        var name = getWebappName()
        if (typeof(name) === 'string' && name.length !== 0) {
            return name
        } else if (webappViewTitle) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Morph Web Browser").arg(webappViewTitle)
        } else {
            return i18n.tr("Morph Web Browser")
        }
    }

    Component {
        id: webappViewComponent

        WebApp {
            id: browser

            settings: root.settings

            window: root

            url: accountProvider.length !== 0 ? "" : root.url

            accountSwitcher: root.accountSwitcher

            dataPath: webappDataLocation
            chromeVisible: root.chromeVisible
            backForwardButtonsVisible: root.backForwardButtonsVisible
            developerExtrasEnabled: root.developerExtrasEnabled
            webappModelSearchPath: root.webappModelSearchPath
            webappUrlPatterns: root.webappUrlPatterns
            blockOpenExternalUrls: root.blockOpenExternalUrls
            openExternalUrlInOverlay: root.openExternalUrlInOverlay
            defaultVideoCaptureDevicePosition: root.defaultVideoCaptureCameraPosition ?
                                                   root.defaultVideoCaptureCameraPosition
                                                 : browser.defaultVideoCaptureDevicePosition
            popupBlockerEnabled: root.popupBlockerEnabled
            hasTouchScreen: root.hasTouchScreen

            focus: true

            popupRedirectionUrlPrefixPattern: root.popupRedirectionUrlPrefixPattern

            localUserAgentOverride: getLocalUserAgentOverrideIfAny()

            runningLocalApplication: root.runningLocalApplication
            webviewOverrideFile: root.webviewOverrideFile

            anchors.fill: parent

            onWebappNameChanged: {
                if (root.webappName !== browser.webappName) {
                    root.webappName = browser.webappName;
                    root.title = getWindowTitle();
                }
            }

            onChooseAccount: {
                showAccountsPage()
                onlineAccountsController.showAccountSwitcher()
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

        property string webContextSessionCookieMode: ""
        property var webappDataLocation

        focus: true

        onLoaded: {
            var context = item.currentWebview.context;
            onlineAccountsController.setupWebcontextForAccount(context);
            item.currentWebview.settings.localContentCanAccessRemoteUrls = localContentCanAccessRemoteUrls;

            loadCustomUserScripts();
            DomainPermissionsModel.databasePath = webappDataLocation + '/domainpermissions.sqlite';
            DomainPermissionsModel.whiteListMode = settings.domainWhiteListMode;
            DomainSettingsModel.databasePath = webappDataLocation + '/domainsettings.sqlite';
            DomainSettingsModel.defaultZoomFactor = settings.zoomFactor;
            DownloadsModel.databasePath = webappDataLocation + "/downloads.sqlite";
            UserAgentsModel.databasePath = DomainSettingsModel.databasePath;

            // this can be set from QtWebEngine version 1.9 (Qt 5.13)
            // see issue [https://github.com/ubports/morph-browser/issues/254]
            // --> uncomment the following line for QtWebEngine >= 1.9, and remove the marked code for this issue in WebApp.qml
            //item.currentWebview.profile.downloadPath = webappDataLocation + "/Downloads";
            FileOperations.mkpath(webappDataLocation + "/Downloads");
        }

        function loadCustomUserScripts() {

            var scripts = [];

            // app specific user scripts
            var idx = webappModel.getWebappIndex(getWebappName());
            var customScripts = webappModel.data(idx, UnityWebApps.UnityWebappsAppModel.Scripts);

            if ((typeof customScripts === "undefined") || (customScripts.length === 0))
            {
                return;
            }

            var i;
            for (i = 0; i < customScripts.length; i++)
            {
              var script = Qt.createQmlObject('import QtWebEngine 1.7; WebEngineScript {}', webappViewLoader);
              script.sourceUrl = customScripts[i];
              script.injectionPoint = WebEngineScript.DocumentCreation;
              script.worldId = WebEngineScript.MainWorld;
              script.runOnSubframes = true;
              scripts.push(script);
            }

            // global user scripts
            for (i = 0; i < item.currentWebview.profile.userScripts.length; i++) {
              scripts.push(item.currentWebview.profile.userScripts[i]);
            }

            item.currentWebview.profile.userScripts = scripts;
        }
    }

    property var settings: Settings {
        property bool domainWhiteListMode: false;
        property bool autoFitToWidthEnabled: false;
        property real zoomFactor: 1.0;

        function restoreDefaults() {
            domainWhiteListMode = false;
            autoFitToWidthEnabled = false;
            zoomFactor = 1.0;
        }

        function resetDomainPermissions() {
            DomainPermissionsModel.deleteAndResetDataBase();
        }

        function resetDomainSettings() {
            DomainSettingsModel.deleteAndResetDataBase();
            // it is a common database with DomainSettingsModel, so it is only for reset here
            UserAgentsModel.deleteAndResetDataBase();
        }
    }

    OnlineAccountsController {
        id: onlineAccountsController
        anchors.fill: parent
        z: -1 // This is needed to have the dialogs shown; see above comment about bug 1398046
        providerId: accountProvider
        applicationId: unversionedAppId
        accountSwitcher: root.accountSwitcher
        webappName: getWebappName()
        webappIcon: root.webappIcon

        onAccountSelected: {
            var newWebappDataLocation = dataLocation + accountDataLocation
            console.log("Loading webview on " + newWebappDataLocation)
            if (newWebappDataLocation === webappViewLoader.webappDataLocation) {
                showWebView()
                return
            }
            webappViewLoader.sourceComponent = null
            webappViewLoader.webappDataLocation = newWebappDataLocation
            // If we need to preserve session cookies, make sure that the
            // mode is "restored" and not "persistent", or the cookies
            // transferred from OA would be lost.
            // We check if the webContextSessionCookieMode is defined and, if so,
            // we override it in the webapp loader.
            if (willMoveCookies && typeof webContextSessionCookieMode === "string") {
                webappViewLoader.webContextSessionCookieMode = "restored"
            }
            webappViewLoader.sourceComponent = webappViewComponent
        }
        onContextReady: startBrowsing()
        onQuitRequested: Qt.quit()
    }

    Component.onCompleted: {
      //  console.info("webapp-container using QtWebEngine %1 (chromium %2)".arg(Oxide.version).arg(Oxide.chromiumVersion))
        i18n.domain = "morph-browser"
        if (forceFullscreen) {
            showFullScreen()
        } else if (startMaximized) {
            showMaximized()
        } else {
            show()
        }
    }

    function showWebView() {
        onlineAccountsController.visible = false
        webappViewLoader.visible = true
    }

    function showAccountsPage() {
        webappViewLoader.visible = false
        onlineAccountsController.visible = true
    }

    function startBrowsing() {
        console.log("Start browsing")
        // This will activate the UnityWebApp element used in WebApp.qml
        webappViewLoader.item.webappName = root.webappName

        // As we use StateSaver to restore the URL, we need to check first if
        // it has not been set previously before setting the URL to the default property
        // homepage.
        var webView = webappViewLoader.item.currentWebview
        var current_url = webView.url.toString();
        if (!current_url || current_url.length === 0) {
            webView.url = root.url
        }
        showWebView()
    }

    function makeUrlFromResult(result) {
        var scheme = null
        var hostname = null
        var url = root.currentWebview.url || root.url
        if (result.host
                && result.host.length !== 0) {
            hostname = result.host
        }
        else {
            var matchHostname = url.toString().match(/.*:\/\/([^/]*)\/.*/)
            if (matchHostname.length > 1) {
                hostname = matchHostname[1]
            }
        }

        if (result.scheme
                && result.scheme.length !== 0) {
            scheme = result.scheme
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
                + (result.path
                    ? result.path : "")
    }

    /**
     *
     */
    function translateHandlerUri(uri) {
        //
        var scheme = uri.substr(0, uri.indexOf(":"))
        if (scheme.indexOf("http") === 0) {
            schemeUriHandleFilterResult(uri)
            return uri
        }

        var result = webappSchemeFilter.applyFilter(uri)
        var mapped_uri = makeUrlFromResult(result)

        uri = mapped_uri

        // Report the result of the intent uri filtering (if any)
        // Done for testing purposed. It is not possible at this point
        // to have AP call a slot and retrieve its result synchronously.
        schemeUriHandleFilterResult(uri)

        return uri
    }

    function openUrls(urls) {
        // only consider the first one (if multiple)
        if (urls.length === 0 || !root.currentWebview) {
            return;
        }
        var requestedUrl = urls[0].toString();

        if (popupRedirectionUrlPrefixPattern.length !== 0
                && requestedUrl.match(popupRedirectionUrlPrefixPattern)) {
            return;
        }

        requestedUrl = translateHandlerUri(requestedUrl);

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
