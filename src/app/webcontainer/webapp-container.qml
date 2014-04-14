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
    objectName: "webappContainer"

    property alias developerExtrasEnabled: browser.developerExtrasEnabled

    property alias backForwardButtonsVisible: browser.backForwardButtonsVisible
    property alias addressBarVisible: browser.addressBarVisible

    property alias url: browser.url
    property alias webappName: browser.webappName
    property alias webappModelSearchPath: browser.webappModelSearchPath
    property alias webappUrlPatterns: browser.webappUrlPatterns
    property alias oxide: browser.oxide

    contentOrientation: browser.screenOrientation

    width: 800
    height: 600

    title: {
        if (typeof(webappName) === 'string' && webappName.length !== 0) {
            return webappName
        } else if (browser.title) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
        } else {
            return i18n.tr("Ubuntu Web Browser")
        }
    }

    WebApp {
        id: browser

        property int screenOrientation: Screen.orientation

        chromeless: !backForwardButtonsVisible && !addressBarVisible
        webbrowserWindow: webbrowserWindowProxy

        anchors.fill: parent

        Component.onCompleted: i18n.domain = "webbrowser-app"
    }
}
