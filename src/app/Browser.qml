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
import QtWebKit 3.1
import QtWebKit.experimental 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.1
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import "actions" as Actions

MainView {
    id: browser

    property bool chromeless: false
    property bool developerExtrasEnabled: false

    property var webappUrlPatterns: null

    property bool webapp: false
    property string webappName: ""
    property string webappModelSearchPath: ""

    property alias currentIndex: tabsModel.currentIndex
    property alias currentWebview: tabsModel.currentWebview
    property string title: currentWebview ? currentWebview.title : ""

    property bool backForwardButtonsVisible: true
    property bool activityButtonVisible: true
    property bool addressBarVisible: true

    property var webbrowserWindow: null

    automaticOrientation: true

    // XXX: not using this property yet since the MainView doesn’t provide
    // a way to know when the keyboard animation has finished (needed for
    // autopilot tests). See the KeyboardRectangle component.
    //anchorToKeyboard: true

    focus: true

    actions: [
        Actions.GoTo {
            enabled: !isRunningAsANamedWebapp()
            onTriggered: currentWebview.url = value
        },
        Actions.Back {
            enabled: currentWebview && !isRunningAsANamedWebapp() ? currentWebview.canGoBack : false
            onTriggered: currentWebview.goBack()
        },
        Actions.Forward {
            enabled: currentWebview && !isRunningAsANamedWebapp() ? currentWebview.canGoForward : false
            onTriggered: currentWebview.goForward()
        },
        Actions.Reload {
            enabled: currentWebview && !isRunningAsANamedWebapp()
            onTriggered: currentWebview.reload()
        },
        Actions.Bookmark {
            enabled: currentWebview != null
            onTriggered: bookmarksModel.add(currentWebview.url, currentWebview.title, currentWebview.icon)
        },
        Actions.NewTab {
            enabled: !isRunningAsANamedWebapp()
            onTriggered: browser.newTab("", true)
        },
        Actions.ClearHistory {
            onTriggered: historyModel.clearAll()
        }
    ]

    PageStack {
        id: stack
        Page {
            Item {
                id: webviewContainer
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: parent.height - osk.height
            }

            ErrorSheet {
                anchors.fill: webviewContainer
                visible: currentWebview ? (currentWebview.lastLoadRequestStatus == WebView.LoadFailedStatus) : false
                url: currentWebview ? currentWebview.url : ""
                onRefreshClicked: currentWebview.reload()
            }
        }
    }

    QtObject {
        id: internal

        function onHistoryEntryRequested(url) {
            currentWebview.url = url
            toggleActivityView()
        }

        function onNewTabRequested() {
            toggleActivityView()
            newTab("", true)
        }

        function onSwitchToTabRequested(index) {
            switchToTab(index)
            toggleActivityView()
        }

        function onCloseTabRequested(index) {
            closeTab(index)
            if (tabsModel.count === 0) {
                onNewTabRequested()
            }
        }

        function onBookmarkRequested(url) {
            currentWebview.url = url
            toggleActivityView()
        }
    }

    property bool activityViewVisible: stack.depth > 0

    function showActivityView() {
        stack.push(Qt.resolvedUrl("ActivityView.qml"),
                   {tabsModel: tabsModel,
                    historyModel: historyModel,
                    bookmarksModel: bookmarksModel})
        var view = stack.currentPage
        view.onHistoryEntryRequested.connect(internal.onHistoryEntryRequested)
        view.onNewTabRequested.connect(internal.onNewTabRequested)
        view.onSwitchToTabRequested.connect(internal.onSwitchToTabRequested)
        view.onCloseTabRequested.connect(internal.onCloseTabRequested)
        view.onBookmarkRequested.connect(internal.onBookmarkRequested)
        if (currentWebview) {
            currentWebview.forceActiveFocus()
        }
        panel.close()
    }

    function hideActivityView() {
        stack.pop()
    }

    function toggleActivityView() {
        if (activityViewVisible) {
            hideActivityView()
        } else {
            showActivityView()
        }
    }

    PanelLoader {
        id: panel

        currentWebview: browser.currentWebview

        anchors {
            left: parent.left
            right: parent.right
            bottom: panel.opened ? osk.top : parent.bottom
        }

        onUrlValidated: {
            if (activityViewVisible) {
                hideActivityView()
            }
        }

        onToggleActivityViewClicked: toggleActivityView()
    }

    Suggestions {
        opacity: (panel.chrome && (panel.state == "spread") &&
                  panel.chrome.addressBar.activeFocus && (count > 0)) ? 1.0 : 0.0
        Behavior on opacity {
            UbuntuNumberAnimation {}
        }
        enabled: opacity > 0
        anchors {
            bottom: panel.top
            horizontalCenter: parent.horizontalCenter
        }
        width: panel.width - units.gu(5)
        height: Math.min(contentHeight, panel.y - units.gu(2))
        model: historyMatches
        onSelected: {
            currentWebview.url = url
            currentWebview.forceActiveFocus()
        }
    }

    KeyboardRectangle {
        id: osk
    }

    HistoryModel {
        id: historyModel
        databasePath: dataLocation + "/history.sqlite"
    }

    HistoryMatchesModel {
        id: historyMatches
        sourceModel: historyModel
        query: panel.chrome ? panel.chrome.addressBar.text : ""
    }

    TabsModel {
        id: tabsModel
    }

    Loader {
        id: webappsComponentLoader
        sourceComponent: (browser.webapp && tabsModel.currentIndex > -1) ? webappsComponent : undefined

        Component {
            id: webappsComponent

            UnityWebApps.UnityWebApps {
                name: browser.webappName
                bindee: tabsModel.currentWebview
                actionsContext: browser.actionManager.globalContext
                model: UnityWebApps.UnityWebappsAppModel { searchPath: browser.webappModelSearchPath }
            }
        }
    }


    BookmarksModel {
        id: bookmarksModel
        databasePath: dataLocation + "/bookmarks.sqlite"
    }

    Component {
        id: webviewComponent

        WebViewImpl {
            id: webview

            currentWebview: browser.currentWebview
            toolbar: panel.panel

            anchors.fill: parent

            enabled: stack.depth === 0
            visible: currentWebview === webview

            experimental.preferences.developerExtrasEnabled: browser.developerExtrasEnabled

            contextualActions: ActionList {
                Actions.OpenLinkInNewTab {
                    enabled: contextualData.href.toString()
                    onTriggered: browser.newTab(contextualData.href, true)
                }
                Actions.BookmarkLink {
                    enabled: contextualData.href.toString()
                    onTriggered: bookmarksModel.add(contextualData.href, contextualData.title, "")
                }
                Actions.CopyLink {
                    enabled: contextualData.href.toString()
                    onTriggered: Clipboard.push([contextualData.href])
                }
                Actions.OpenImageInNewTab {
                    enabled: contextualData.img.toString()
                    onTriggered: browser.newTab(contextualData.img, true)
                }
                Actions.CopyImage {
                    enabled: contextualData.img.toString()
                    onTriggered: Clipboard.push([contextualData.img])
                }
            }

            function navigationRequestedDelegate(request) {
                if (! request.isMainFrame) {
                    request.action = WebView.AcceptRequest;
                    return;
                }

                var action = WebView.AcceptRequest;
                var url = request.url.toString();

                // The list of url patterns defined by the webapp takes precedence over command line
                if (webapp && isRunningAsANamedWebapp()) {
                    var webappComponent = webappsComponentLoader.item;

                    if (webappComponent != null &&
                        webappComponent.model.exists(webappComponent.name) &&
                        ! webappComponent.model.doesUrlMatchesWebapp(webappComponent.name, url)) {
                        action = WebView.IgnoreRequest;
                    }
                }
                else if (browser.webappUrlPatterns && browser.webappUrlPatterns.length !== 0) {
                    action = WebView.IgnoreRequest;
                    for (var i = 0; i < browser.webappUrlPatterns.length; ++i) {
                        var pattern = browser.webappUrlPatterns[i];
                        if (url.match(pattern)) {
                            action = WebView.AcceptRequest;
                            break;
                        }
                    }
                }

                request.action = action;
                if (action === WebView.IgnoreRequest) {
                    Qt.openUrlExternally(url);
                }
            }

            onNewTabRequested: {

                if (webapp) {
                    Qt.openUrlExternally(url);
                }
                else {
                    browser.newTab(url, true);
                }
            }

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
                return UnityWebAppsUtils.makeProxiesForQtWebViewBindee(webview, eventHandlers)
            }
        }
    }

    function isRunningAsANamedWebapp() {
        return browser.webappName && typeof(browser.webappName) === 'string' && browser.webappName.length != 0
    }

    function newTab(url, setCurrent) {
        var webview = webviewComponent.createObject(webviewContainer, {"url": url})
        var index = tabsModel.add(webview)
        if (setCurrent) {
            tabsModel.currentIndex = index
            if (!browser.chromeless) {
                if (!url) {
                    panel.chrome.addressBar.forceActiveFocus()
                    panel.open()
                }
            }
        }
    }

    function closeTab(index) {
        var webview = tabsModel.remove(index)
        if (webview) {
            webview.destroy()
        }
    }

    function switchToTab(index) {
        tabsModel.currentIndex = index
        currentWebview.forceActiveFocus()
    }
}
