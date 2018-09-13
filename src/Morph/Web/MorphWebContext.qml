/*
 * Copyright 2014-2015 Canonical Ltd.
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

import QtQuick 2.4
import QtWebEngine 1.5

WebEngineProfile {
    id: oxideContext

    property alias userAgent: httpUserAgent
    property alias dataPath: persistentStoragePath
    property alias maxCacheSizeHint: httpCacheMaximumSize

    readonly property string defaultUserAgent: __ua.defaultUA

    dataPath: dataLocation

    cachePath: cacheLocation
    maxCacheSizeHint: cacheSizeHint

    userAgent: defaultUserAgent

    persistentCookiesPolicy: {
        if (typeof webContextSessionCookieMode !== 'undefined') {
            if (webContextSessionCookieMode === "persistent") {
                return WebEngineProfile.ForcePersistentCookies
            } else if (webContextSessionCookieMode === "restored") {
                return WebEngineProfile.AllowPersistentCookies
            }
        }
        return WebEngineProfile.NoPersistentCookies
    }

    userScripts: [
        WebEngineScript {
            context: "oxide://smartbanners/"
            sourceUrl: Qt.resolvedUrl("smartbanners.js")
            runOnSubframes: true
        },
        WebEngineScript {
            context: "oxide://twitter-no-omniprompt/"
            sourceUrl: Qt.resolvedUrl("twitter-no-omniprompt.js")
            runOnSubframes: true
        },
        WebEngineScript {
            context: "oxide://fb-no-appbanner/"
            sourceUrl: Qt.resolvedUrl("fb-no-appbanner.js")
            runOnSubframes: true
        /*
        },
        WebEngineScript {
            context: "oxide://selection/"
            sourceUrl: Qt.resolvedUrl("selection02.js")
            runOnSubframes: true
        */
        }
    ]

    property QtObject __ua: UserAgent02 {
        onScreenSizeChanged: reloadOverrides()
        Component.onCompleted: reloadOverrides()

        property string _target: ""

        function reloadOverrides() {
            if (screenSize === "unknown") {
                return
            }
            var target = screenSize === "small" ? "mobile" : "desktop"
            if (target == _target) return
            _target = target
            var script = "ua-overrides-%1.js".arg(target)
            var temp = null
            try {
                temp = Qt.createQmlObject('import QtQml 2.0; import "%1" as Overrides; QtObject { readonly property var overrides: Overrides.overrides }'.arg(script), oxideContext)
            } catch (e) {
                console.error("No overrides found for", target)
            }
            if (temp !== null) {
                console.log("Loaded %1 UA override(s) from %2".arg(temp.overrides.length).arg(Qt.resolvedUrl(script)))
                var chromiumVersion = "65.0.3325.151" // TODO: find out how to get this from QtWebEngine
                var overrides = []
                for (var o in temp.overrides) {
                    var override = temp.overrides[o]
                    overrides.push([override[0], override[1].replace(/\$\{CHROMIUM_VERSION\}/g, chromiumVersion)])
                }
                userAgentOverrides = overrides
                temp.destroy()
            }
        }
    }

    /*
    devtoolsEnabled: webviewDevtoolsDebugPort !== -1
    devtoolsPort: webviewDevtoolsDebugPort
    devtoolsIp: webviewDevtoolsDebugHost

    hostMappingRules: webviewHostMappingRules
    */
}
