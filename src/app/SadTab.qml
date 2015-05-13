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
import Ubuntu.Components 1.1
import com.canonical.Oxide 1.8 as Oxide

Rectangle {
    property var webview

    signal closeTabRequested()

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(4)

        spacing: units.gu(3)

        Label {
            anchors {
                left: parent.left
                right: parent.right
            }
            fontSize: "x-large"
            text: i18n.tr("Aww, snap!")
        }

        Label {
            anchors {
                left: parent.left
                right: parent.right
            }
            text: {
                if (!webview) return ""
                if (webview.webProcessStatus == Oxide.WebView.WebProcessKilled) {
                    return "killed"
                } else if (webview.webProcessStatus == Oxide.WebView.WebProcessCrashed) {
                    return "crashed"
                } else {
                    return ""
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(3)

            Button {
                text: i18n.tr("Close tab")
                onClicked: closeTabRequested()
            }

            Button {
                text: i18n.tr("Reload")
                onClicked: webview.reload()
            }
        }
    }
}
