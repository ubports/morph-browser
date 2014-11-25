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
import com.canonical.Oxide 1.0 as Oxide
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Ubuntu.Web 0.2
import "../actions" as Actions
import ".."

WebViewImpl {
    id: webview

    property bool developerExtrasEnabled: false
    property string webappName: ""
    property string localUserAgentOverride: ""
    property var webappUrlPatterns: null
    property string popupRedirectionUrlPrefixPattern: ""
    property url dataPath

    // Mostly used for testing & avoid external urls to
    //  "leak" in the default browser
    property bool blockOpenExternalUrls: false

    // Those signals are used for testing purposes to externally
    //  track down the various internal logic & steps of a popup lifecycle.
    signal openExternalUrlTriggered(string url)
    signal gotRedirectionUrl(string url)
    property bool runningLocalApplication: false

    currentWebview: webview

    context: WebContext {
        dataPath: webview.dataPath
    }

    preferences.allowFileAccessFromFileUrls: runningLocalApplication
    preferences.allowUniversalAccessFromFileUrls: runningLocalApplication

    contextualActions: ActionList {
        Actions.CopyLink {
            enabled: webview.contextualData.href.toString()
            onTriggered: Clipboard.push([webview.contextualData.href])
        }
        Actions.CopyImage {
            enabled: webview.contextualData.img.toString()
            onTriggered: Clipboard.push([webview.contextualData.img])
        }
    }

    StateSaver.properties: "url"
    StateSaver.enabled: !runningLocalApplication

    function shouldOpenPopupsInDefaultBrowser() {
        return formFactor !== "desktop";
    }

    // Function defined by the UbuntuWebView and overridden here to handle potential webapp defined UA overrides
    function getUAString() {
        return webview.localUserAgentOverride.length === 0 ? undefined : webview.localUserAgentOverride
    }

    function isRunningAsANamedWebapp() {
        return webview.webappName && typeof(webview.webappName) === 'string' && webview.webappName.length != 0
    }

    function haveValidUrlPatterns() {
        return webappUrlPatterns && webappUrlPatterns.length !== 0
    }

    function isNewForegroundWebViewDisposition(disposition) {
        return disposition === Oxide.NavigationRequest.DispositionNewPopup ||
               disposition === Oxide.NavigationRequest.DispositionNewForegroundTab;
    }

    function openUrlExternally(url) {
        webview.openExternalUrlTriggered(url)
        if (! webview.blockOpenExternalUrls) {
            Qt.openUrlExternally(url)
        }
    }

    function shouldAllowNavigationTo(url) {
        // The list of url patterns defined by the webapp takes precedence over command line
        if (isRunningAsANamedWebapp()) {
            if (unityWebapps.model.exists(unityWebapps.name) &&
                unityWebapps.model.doesUrlMatchesWebapp(unityWebapps.name, url)) {
                return true;
            }
        }

        // We still take the possible additional patterns specified in the command line
        // (the in the case of finer grained ones specifically for the container and not
        // as an 'install source' for the webapp).
        if (haveValidUrlPatterns()) {
            for (var i = 0; i < webappUrlPatterns.length; ++i) {
                var pattern = webappUrlPatterns[i]
                if (url.match(pattern)) {
                    return true;
                }
            }
        }

        return false;
    }

    function navigationRequestedDelegate(request) {
        var newForegroundPageRequest = isNewForegroundWebViewDisposition(request.disposition)
        var url = request.url.toString()

        console.log("navigationRequestedDelegate - newForegroundPageRequest: "
                    + newForegroundPageRequest
                    + ', url: ' + url)

        if (runningLocalApplication && url.indexOf("file://") !== 0) {
            request.action = Oxide.NavigationRequest.ActionReject
            openUrlExternally(url)
            return
        }

        // Covers some edge cases corresponding to the default window.open() behavior.
        // When it is being called, the targetted URL will not load right away but
        // will first round trip to an "about:blank".
        // See https://developer.mozilla.org/en-US/docs/Web/API/Window.open
        if (newForegroundPageRequest) {
            if (url == 'about:blank') {
                console.log('Accepting a new window request to navigate to "about:blank"')
                request.action = Oxide.NavigationRequest.ActionAccept
                return
            }

            var isRedirectionUrl = false;
            var targetUrl = url;
            if (popupRedirectionUrlPrefixPattern) {
                // NOTE: very nasty workaround to be backward compatibility, will be deleted as soon
                // as the FB webapp is updated.
                if (popupRedirectionUrlPrefixPattern.indexOf('(') === -1) {
                    isRedirectionUrl = (url.indexOf(popupRedirectionUrlPrefixPattern) === 0);
                    targetUrl = isRedirectionUrl ?
                                url.slice(popupRedirectionUrlPrefixPattern.length) : url;

                    // Quick fix for http://pad.lv/1358622 (trim trailing parameters).
                    var extraParams = targetUrl.indexOf("&");
                    if (extraParams !== -1) {
                        targetUrl = targetUrl.slice(0, extraParams);
                    }
                } else {
                    var redirectionPatternMatch = url.match(popupRedirectionUrlPrefixPattern);
                    isRedirectionUrl =
                        popupRedirectionUrlPrefixPattern
                        && redirectionPatternMatch
                        && redirectionPatternMatch.length >= 2;

                    // Assume that the first group is the matching one
                    targetUrl = isRedirectionUrl ?
                                redirectionPatternMatch[1] : url;
                }
            }

            if (isRedirectionUrl) {
                console.debug("Got a redirection URL with target URL: " + targetUrl)
                targetUrl = decodeURIComponent(targetUrl)
                gotRedirectionUrl(targetUrl)
            }

            if (webview.shouldAllowNavigationTo(targetUrl)) {
                console.debug('Redirecting popup browsing ' + targetUrl + ' in the current container window.')
                request.action = Oxide.NavigationRequest.ActionReject
                webappContainerHelper.browseToUrlRequested(webview, targetUrl)
                return
            }

            if (shouldOpenPopupsInDefaultBrowser()) {
                console.debug('Opening popup window ' + targetUrl + ' in the browser window.')
                request.action = Oxide.NavigationRequest.ActionReject
                openUrlExternally(targetUrl)
                return;
            }
            return
        }

        // Pass-through if we are not running as a named webapp (--webapp='Gmail')
        // or if we dont have a list of url patterns specified to filter the
        // browsing actions
        if ( ! webview.haveValidUrlPatterns() && ! webview.isRunningAsANamedWebapp()) {
            request.action = Oxide.NavigationRequest.ActionAccept
            return
        }

        request.action = Oxide.NavigationRequest.ActionReject
        if (webview.shouldAllowNavigationTo(url))
            request.action = Oxide.NavigationRequest.ActionAccept

        // SAML requests are used for instance by Google Apps for your domain;
        // they are implemented as a HTTP redirect to a URL containing the
        // query parameter called "SAMLRequest".
        // Besides letting the request through, we must also add the SAML
        // domain to the list of the allowed hosts.
        if (request.disposition === Oxide.NavigationRequest.DispositionCurrentTab &&
            url.indexOf("SAMLRequest") > 0) {
            var urlRegExp = new RegExp("https?://([^?/]+)")
            var match = urlRegExp.exec(url)
            var host = match[1]
            var escapeDotsRegExp = new RegExp("\\.", "g")
            var hostPattern = "https?://" + host.replace(escapeDotsRegExp, "\\.") + "/"
            console.log("SAML request detected. Adding host pattern: " + hostPattern)
            webappUrlPatterns.push(hostPattern)
            request.action = Oxide.NavigationRequest.ActionAccept
        }

        if (request.action === Oxide.NavigationRequest.ActionReject) {
            console.debug('Opening: ' + url + ' in the browser window.')
            openUrlExternally(url)
        }
    }

    function createPopupWindow(request) {
        popupWebViewFactory.createObject(webview, { request: request, width: 500, height: 800 });
    }

    Component {
        id: popupWebViewFactory
        Window {
            id: popup
            property alias request: popupBrowser.request
            WebView {
                id: popupBrowser
                anchors.fill: parent

                function navigationRequestedDelegate(request) {
                    var url = request.url.toString()

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

                onNewViewRequested: webview.createPopupWindow(request)

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
                    var _url = url.toString();
                    if (_url.trim().length === 0)
                        return;

                    if (_url != 'about:blank' && ! webview.shouldAllowNavigationTo(_url)) {
                        openUrlExternally(_url);
                        popup.close()
                    }
                }
            }
            Component.onCompleted: popup.show()
        }
    }

    onNewViewRequested: createPopupWindow(request)

    preferences.localStorageEnabled: true
    preferences.appCacheEnabled: true

    // Small shim needed when running as a webapp to wire-up connections
    // with the webview (message received, etc…).
    // This is being called (and expected) internally by the webapps
    // component as a way to bind to a webview lookalike without
    // reaching out directly to its internals (see it as an interface).
    function getUnityWebappsProxies() {
        var eventHandlers = {
            onAppRaised: function () {
                if (webbrowserWindow) {
                    try {
                        webbrowserWindow.raise();
                    } catch (e) {
                        console.debug('Error while raising: ' + e);
                    }
                }
            }
        };
        return UnityWebAppsUtils.makeProxiesForWebViewBindee(webview, eventHandlers)
    }

    onGeolocationPermissionRequested: {
        if (formFactor == "desktop") {
            requestGeolocationPermission(request)
        } else {
            // On devices where webapps are confined, trying to access the
            // location service will trigger a system prompt from the trust
            // store, so we don’t need a custom prompt.
            request.accept()
        }
    }
}
