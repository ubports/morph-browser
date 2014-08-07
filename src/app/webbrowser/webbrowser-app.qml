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

Window {
    property alias searchEngine: browser.searchEngine
    property alias developerExtrasEnabled: browser.developerExtrasEnabled
    property alias restoreSession: browser.restoreSession

    property alias homepage: browser.homepage
    property alias urls: browser.initialUrls

    contentOrientation: browser.screenOrientation

    width: 800
    height: 600

    title: {
        if (browser.title) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
        } else {
            return i18n.tr("Ubuntu Web Browser")
        }
    }

    Browser {
        id: browser
        property int screenOrientation: Screen.orientation
        anchors.fill: parent
        webbrowserWindow: webbrowserWindowProxy

        Component.onCompleted: i18n.domain = "webbrowser-app"
    }

    // XXX: work around https://bugs.launchpad.net/unity8/+bug/1328839
    // by toggling fullscreen on the window only on desktop.
    visibility: browser.currentWebview && browser.currentWebview.fullscreen && (formFactor === "desktop") ? Window.FullScreen : Window.AutomaticVisibility

    // Handle runtime requests to open urls as defined
    // by the freedesktop application dbus interface's open
    // method for DBUS application activation:
    // http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#dbus
    // The dispatch on the org.freedesktop.Application if is done per appId at the
    // url-dispatcher/upstart level.
    Connections {
        target: UriHandler
        onOpened: {
            for (var i = 0; i < uris.length; ++i) {
                newTab(uris[i], i == uris.length - 1)
            }
        }
    }
}
