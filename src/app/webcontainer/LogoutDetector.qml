/*
 * Copyright 2015 Canonical Ltd.
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

QtObject {
    id: root

    property var webview: null
    property string logoutUrlPattern: ""
    property string logoutSelectors: ""

    signal logoutDetected()

    property var __scriptMessageHandler: ScriptMessageHandler {
        msgId: "domChanged"
        contexts: ["oxide://bla/"]
        callback: function(msg, frame) {
            console.log('Got a DOM changed message: ' + msg.args)
            var request = webview.rootFrame.sendMessage(
                "oxide://bla/",
                "evaluateSelectors",
                { selectors: root.logoutSelectors }
            )

            // NOTE: does not handle error
            request.onreply = function(response) {
                console.log('Selector result: ' + response.result)
            }
        }
    }

    property var __connections: Connections {
        target: webview
        onLoadEvent: {
            console.log("Load event: " + event.url)
            if (logoutUrlPattern.length !== 0 && event.url.toString().match(logoutUrlPattern)) {
                root.logoutDetected()
            }
        }
    }

    property var __userScript: UserScript {
        context: "oxide://bla/"
        url: Qt.resolvedUrl("logout-detector.js")
        incognitoEnabled: true
        matchAllFrames: true
    }

    onWebviewChanged: {
        if (!webview) return
        console.log("Webview changed, adding script")
        webview.addMessageHandler(__scriptMessageHandler)
        webview.context.addUserScript(__userScript)
    }
}
