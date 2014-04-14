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

pragma Singleton

import QtQuick 2.0
import com.canonical.Oxide 1.0

Item {
    property string customUA: userAgent.defaultUA

    property QtObject sharedContext: WebContext {
        dataPath: dataLocation
        userAgent: customUA
        networkRequestDelegate: WebContextDelegateWorker {
            source: Qt.resolvedUrl("ua-override-worker.js")
            onMessage: console.log("Overriden UA for", message.url, ":", message.override)
            Component.onCompleted: {
                var script = "ua-overrides-%1.js".arg(formFactor)
                var temp = null
                try {
                    temp = Qt.createQmlObject('import QtQml 2.0; import "%1" as Overrides; QtObject { readonly property var overrides: Overrides.overrides }'.arg(script), this)
                } catch (e) {
                    console.error("No overrides found for", formFactor)
                }
                if (temp !== null) {
                    console.log("Loaded %1 UA override(s) from %2".arg(temp.overrides.length).arg(Qt.resolvedUrl(script)))
                    sendMessage({overrides: temp.overrides})
                    temp.destroy()
                }
            }
        }
        userAgentOverrideDelegate: networkRequestDelegate
        sessionCookieMode: {
            if (typeof webContextSessionCookieMode !== 'undefined') {
                if (webContextSessionCookieMode === "persistent") {
                    return WebContext.SessionCookieModePersistent
                } else if (webContextSessionCookieMode === "restored") {
                    return WebContext.SessionCookieModeRestored
                } 
            }
            return WebContext.SessionCookieModeEphemeral
        }
        userScripts: [
            UserScript {
                context: "oxide://selection/"
                url: Qt.resolvedUrl("selection02.js")
                incognitoEnabled: true
                matchAllFrames: true
            }
        ]
    }

    UserAgent02 {
        id: userAgent
    }
}
