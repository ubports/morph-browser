/*
 * Copyright 2013-2016 Canonical Ltd.
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

import QtQml 2.0
import QtQuick.Window 2.2

/*
 * Useful documentation:
 *   http://en.wikipedia.org/wiki/User_agent#Format
 *   https://developer.mozilla.org/en-US/docs/Gecko_user_agent_string_reference
 *   https://wiki.mozilla.org/B2G/User_Agent
 *   https://github.com/mozilla-b2g/gaia/blob/master/build/ua-override-prefs.js
 *   https://developers.google.com/chrome/mobile/docs/user-agent
 */

QtObject {
    // Empirical value: screens smaller than 19cm are considered small enough that a
    // mobile UA string is used, screens bigger than that will get desktop content.
    property string screenSize: calcScreenSize()

    // {ubuntuVersion}: Ubuntu version, e.g. "14.04" (currently not used)
    // {platformAttributes}: optional token to specify further attributes of the platform, e.g. "like Android"
    // {hardwareId}: optional hardware ID token
    // {webKitVersion}: WebKit version, e.g. "537.36"
    // {chromiumVersion}: Chromium version, e.g. "35.0.1870.2"
    // {mobileSuffix}: Optional token to provide additional free-form information, e.g. "Mobile"
    // {safariVersion}: Safari version, e.g. "537.36"
    // {additionalInfo}: Optional token, in case some extra bits are needed to make things work (e.g. an extra form factor info etc.)
    //
    // note #1: "Mozilla/5.0" is misinformation, but it is a legacy token that
    //   virtually every single UA out there has, it seems unwise to remove it
    // note #2: "AppleWebKit", as opposed to plain "WebKit", does make a
    //   difference in the content served by certain sites (e.g. gmail.com)
    //readonly property string _template: "Mozilla/5.0 (Linux; Ubuntu %1%2%3) AppleWebKit/%4 Chromium/%5 %6Safari/%7%8"

    readonly property string _template: "Mozilla/5.0 (Linux {hardwareId} {platformAttributes}) AppleWebKit/{webKitVersion} (KHTML, like Gecko) QtWebEngine/5.10.1 Chromium/{chromiumVersion} {mobileSuffix} Safari/{webKitVersion} {mobileSuffix} {more}"
    readonly property string _attributes: screenSize === "small" ? " like Android 5.1.1" : ""
    readonly property string _hardwareID: "armv7l"
    readonly property string _webkitVersion: "537.36"
    readonly property string _chromiumVersion: "61.0.3163.140"
    readonly property string _formFactor: screenSize === "small" ? "Mobile" : ""
    readonly property string _more: ""

    function setDesktopMode(val) {
        screenSize = val ? "large" : calcScreenSize()
    }

    function calcScreenSize() {
        var screenDiagonal = Math.sqrt(Screen.width * Screen.width + Screen.height * Screen.height)
        return "small"
        //return (screenDiagonal === 0) ? "unknown" : (screenDiagonal > 0 && screenDiagonal < 190) ? "small" : "large"
    }

    property string defaultUA: {
        var ua = _template
        ua = ua.replace("{hardwareId}", _hardwareID)
        ua = ua.replace("{platformAttributes}", _attributes)
        ua = ua.replace("{webKitVersion}", _webkitVersion).replace("{webKitVersion}", _webkitVersion) // 2 times
        ua = ua.replace("{mobileSuffix}", _formFactor).replace("{mobileSuffix}", _formFactor) // 2 times
        ua = ua.replace("{chromiumVersion}", _chromiumVersion)
        ua = ua.replace("{more}", _more)
        return ua
    }
}
