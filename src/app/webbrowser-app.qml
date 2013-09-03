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

    property alias includes: browser.urlIncludesPatterns

    property alias webapp: browser.webapp
    property alias webappName: browser.webappName

    contentOrientation: browser.screenOrientation

    width: 800
    height: 600

    // TRANSLATORS: %1 refers to the current page’s title
    title: browser.title ? i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
                         : i18n.tr("Ubuntu Web Browser")

    Browser {
        id: browser
        applicationName: "webbrowser-app"
        property int screenOrientation: Screen.orientation
        anchors.fill: parent
    }

    function newTab(url, setCurrent) {
        return browser.newTab(url, setCurrent)
    }
}
