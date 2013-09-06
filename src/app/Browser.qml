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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Unity.Action 1.0 as UnityActions
import Ubuntu.UnityWebApps 0.1 as UnityWebApps

MainView {
    id: browser

    property bool chromeless: false
    property real qtwebkitdpr
    property bool developerExtrasEnabled: false

    property var webappUrlPatterns: null

    property bool webapp: false
    property string webappName: ""

    property alias currentIndex: tabsModel.currentIndex
    property alias currentWebview: tabsModel.currentWebview
    property string title: currentWebview ? currentWebview.title : ""

    automaticOrientation: true

    // XXX: not using this property yet since the MainView doesn’t provide
    // a way to know when the keyboard animation has finished (needed for
    // autopilot tests). See the KeyboardRectangle component.
    //anchorToKeyboard: true

    focus: true

    actions: [
        UnityActions.Action {
            text: i18n.tr("Goto")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'Goto' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Address;URL;www")
            parameterType: UnityActions.Action.String
            enabled: !isRunningAsANamedWebapp()
            onTriggered: currentWebview.url = value
        },
        UnityActions.Action {
            text: i18n.tr("Back")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'Back' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Older Page")
            enabled: currentWebview && !isRunningAsANamedWebapp() ? currentWebview.canGoBack : false
            onTriggered: currentWebview.goBack()
        },
        UnityActions.Action {
            text: i18n.tr("Forward")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'Forward' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Newer Page")
            enabled: currentWebview && !isRunningAsANamedWebapp() ? currentWebview.canGoForward : false
            onTriggered: currentWebview.goForward()
        },
        UnityActions.Action {
            text: i18n.tr("Reload")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'Reload' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Leave Page")
            enabled: currentWebview && !isRunningAsANamedWebapp()
            onTriggered: currentWebview.reload()
        },
        UnityActions.Action {
            text: i18n.tr("Bookmark")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'Bookmark' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Add This Page to Bookmarks")
            enabled: currentWebview != null
            onTriggered: bookmarksModel.add(currentWebview.url, currentWebview.title, currentWebview.icon)
        },
        UnityActions.Action {
            text: i18n.tr("New Tab")
            // TRANSLATORS: This is a free-form list of keywords associated to the 'New Tab' action.
            // Keywords may actually be sentences, and must be separated by semi-colons.
            keywords: i18n.tr("Open a New Tab")
            enabled: !isRunningAsANamedWebapp()
            onTriggered: browser.newTab("", true)
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
                height: browser.height - osk.height
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

    function toggleActivityView() {
        if (stack.depth > 0) {
            stack.pop()
        } else {
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
            panel.item.opened = false
        }
    }

    Loader {
        id: panel

        property Item chrome: item ? item.contents[0] : null

        sourceComponent: browser.chromeless ? undefined : panelComponent

        anchors {
            left: parent.left
            right: parent.right
            bottom: (item && item.opened) ? osk.top : parent.bottom
        }

        Component {
            id: panelComponent

            Panel {
                anchors {
                    left: parent ? parent.left : undefined
                    right: parent ? parent.right : undefined
                    bottom: parent ? parent.bottom : undefined
                }
                height: units.gu(8)

                opened: true
                onOpenedChanged: {
                    if (!opened) {
                        Qt.inputMethod.hide()
                    }
                }

                Chrome {
                    anchors.fill: parent

                    url: currentWebview ? currentWebview.url : ""

                    loading: currentWebview ? currentWebview.loading || (currentWebview.loadProgress == 0) : false
                    loadProgress: currentWebview ? currentWebview.loadProgress : 0

                    canGoBack: currentWebview ? currentWebview.canGoBack : false
                    onGoBackClicked: currentWebview.goBack()

                    canGoForward: currentWebview ? currentWebview.canGoForward : false
                    onGoForwardClicked: currentWebview.goForward()

                    onUrlValidated: currentWebview.url = url

                    property bool stopped: false
                    onLoadingChanged: {
                        if (loading) {
                            if (panel.item) {
                                panel.item.opened = true
                            }
                        } else if (stopped) {
                            stopped = false
                        } else if (!addressBar.activeFocus) {
                            if (panel.item) {
                                panel.item.opened = false
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

                    onToggleTabsClicked: toggleActivityView()
                }
            }
        }
    }

    Suggestions {
        opacity: (panel.chrome && (panel.item.state == "spread") &&
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
        sourceComponent: (browser.webapp && tabsModel.currentIndex > -1) ? webappsComponent : undefined

        Component {
            id: webappsComponent

            UnityWebApps.UnityWebApps {
                id: webapps
                name: browser.webappName
                bindee: tabsModel.currentWebview
                actionsContext: browser.actionManager.globalContext
                model: UnityWebApps.UnityWebappsAppModel {}
            }
        }
    }


    BookmarksModel {
        id: bookmarksModel
        databasePath: dataLocation + "/bookmarks.sqlite"
    }

    Component {
        id: webviewComponent

        UbuntuWebView {
            id: webview

            anchors.fill: parent

            enabled: stack.depth === 0
            visible: tabsModel.currentWebview === webview

            devicePixelRatio: browser.qtwebkitdpr

            experimental.preferences.developerExtrasEnabled: browser.developerExtrasEnabled

            selectionActions: ActionList {
                Action {
                    text: i18n.tr("Share")
                    onTriggered: selection.share()
                }
                Action {
                    text: i18n.tr("Save")
                    onTriggered: selection.save()
                }
                Action {
                    text: i18n.tr("Copy")
                    onTriggered: selection.copy()
                }
            }

            experimental.onPermissionRequested: {
                if (permission.type == PermissionRequest.Geolocation) {
                    var text = i18n.tr("This page wants to know your device’s location.")
                    PopupUtils.open(Qt.resolvedUrl("PermissionRequest.qml"),
                                    browser.currentWebview,
                                    {"permission": permission, "text": text})
                }
                // TODO: handle other types of permission requests
                // TODO: we might want to store the answer to avoid requesting
                //       the permission everytime the user visits this site.
            }

            property int lastLoadRequestStatus: -1
            onLoadingChanged: {
                lastLoadRequestStatus = loadRequest.status
                if (loadRequest.status === WebView.LoadSucceededStatus) {
                    historyModel.add(webview.url, webview.title, webview.icon)
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
                if (webapp && isRunningAsANamedWebapp() && webapps.model && webapps.model.exists(webapps.name)) {
                    if ( ! webapps.model.doesUrlMatchesWebapp(webapps.name, url)) {
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

            onNewTabRequested: browser.newTab(url, true)

            // Small shim needed when running as a webapp to wire-up connections
            // with the webview (message received, etc…).
            // This is being called (and expected) internally by the webapps
            // component as a way to bind to a webview lookalike without
            // reaching out directly to its internals (see it as an interface).
            function getUnityWebappsProxies() {
                var handlers = {};
                return UnityWebAppsUtils.makeProxiesForQtWebViewBindee(webview, handlers)
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
                    panel.item.opened = true
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
