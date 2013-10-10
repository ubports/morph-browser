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

Window {
    property alias chromeless: browser.chromeless
    property alias qtwebkitdpr: browser.qtwebkitdpr
    property alias developerExtrasEnabled: browser.developerExtrasEnabled

    property alias webappUrlPatterns: browser.webappUrlPatterns

    property alias backForwardButtonsVisible: browser.backForwardButtonsVisible
    property alias activityButtonVisible: browser.activityButtonVisible
    property alias addressBarVisible: browser.addressBarVisible

    property alias webapp: browser.webapp
    property alias webappName: browser.webappName
    property alias webappModelSearchPath: browser.webappModelSearchPath

    property bool enableUriHandling: false

    contentOrientation: browser.screenOrientation

    width: 800
    height: 600

    title: {
        if (webapp && typeof(webappName) === 'string' && webappName.length !== 0)
            return webappName

        if (browser.title)
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
        else
            return i18n.tr("Ubuntu Web Browser")
    }

    Browser {
        id: browser
        property int screenOrientation: Screen.orientation
        anchors.fill: parent
        webbrowserWindow: webbrowserWindowProxy

        Component.onCompleted: i18n.domain = "webbrowser-app"
    }

    function newTab(url, setCurrent) {
        return browser.newTab(url, setCurrent)
    }

    // Handle runtime requests to open urls as defined
    // by the freedesktop application dbus interface's open
    // method for DBUS application activation:
    // http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#dbus
    // The dispatch on the org.freedesktop.Application if is done per appId at the
    // url-dispatcher/upstart level.
    Connections {
        target: enableUriHandling ? UriHandler : null
        onOpened: {
            for (var i = 0; i < uris.length; ++i) {
                newTab(uris[i], i == uris.length - 1);
            }
        }
    }

}
