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

    // %1: Ubuntu version, e.g. "14.04"
    // %2: optional token to specify further attributes of the platform, e.g. "like Android"
    // %3: optional hardware ID token
    // %4: WebKit version, e.g. "537.36"
    // %5: Chromium version, e.g. "35.0.1870.2"
    // %6: Optional token to provide additional free-form information, e.g. "Mobile"
    // %7: Safari version, e.g. "537.36"
    // %8: Optional token, in case some extra bits are needed to make things work (e.g. an extra form factor info etc.)
    //
    // note #1: "Mozilla/5.0" is misinformation, but it is a legacy token that
    //   virtually every single UA out there has, it seems unwise to remove it
    // note #2: "AppleWebKit", as opposed to plain "WebKit", does make a
    //   difference in the content served by certain sites (e.g. gmail.com)
    readonly property string _template: "Mozilla/5.0 (Linux; Ubuntu %1%2%3) AppleWebKit/%4 Chromium/%5 %6Safari/%7%8"

    readonly property string _attributes: screenSize === "small" ? "like Android 4.4" : ""

    readonly property string _hardwareID: ""

    // See chromium/src/content/webkit_version.h.in in oxide’s source tree.
    readonly property string _webkitVersion: "537.36"

    readonly property string _chromiumVersion: "65.0.3325.151" // TODO figure out how to get this

    readonly property string _formFactor: screenSize === "small" ? "Mobile" : ""

    readonly property string _more: ""

    function setDesktopMode(val) {
        screenSize = val ? "large" : calcScreenSize()
    }

    function calcScreenSize() {
        return (screenDiagonal === 0) ? "unknown" : (screenDiagonal > 0 && screenDiagonal < 190) ? "small" : "large"
    }

    property string defaultUA: {
        var ua = _template
        ua = ua.arg(ubuntuVersion) // %1
        ua = ua.arg((_attributes !== "") ? " %1".arg(_attributes) : "") // %2
        ua = ua.arg((_hardwareID !== "") ? "; %1".arg(_hardwareID) : "") // %3
        ua = ua.arg(_webkitVersion) // %4
        ua = ua.arg(_chromiumVersion) // %5
        ua = ua.arg((_formFactor !== "") ? "%1 ".arg(_formFactor) : "") // %6
        ua = ua.arg(_webkitVersion) // %7
        ua = ua.arg((_more !== "") ? " %1".arg(_more) : "") // %8
        return ua
    }
}
