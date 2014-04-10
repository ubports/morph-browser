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

import QtQuick 2.0
import com.canonical.Oxide 1.0

WebContext {
    dataPath: dataLocation
    userAgent: userAgent02.defaultUA
    networkRequestDelegate: uaOverrideWorker.item
    userAgentOverrideDelegate: networkRequestDelegate
    userScripts: [
        UserScript {
            context: "oxide://selection/"
            url: Qt.resolvedUrl("selection02.js")
            incognitoEnabled: true
            matchAllFrames: true
        }
    ]

    property Item __loader: Loader {
        id: uaOverrideWorker
        sourceComponent: (formFactor === "mobile") ? uaOverrideWorkerComponent : undefined

        Component {
            id: uaOverrideWorkerComponent

            WebContextDelegateWorker {
                source: Qt.resolvedUrl("ua-override-worker.js")
                onMessage: console.log("Overriden UA for", message.url, ":", message.override)
            }
        }

        UserAgent02 {
            id: userAgent02
        }
    }
}
