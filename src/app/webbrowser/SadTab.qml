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
        anchors {
            fill: parent
            margins: units.gu(4)
        }
        spacing: units.gu(3)

        Label {
            anchors {
                left: parent.left
                right: parent.right
            }

            fontSize: "large"
            wrapMode: Text.Wrap
            text: {
                if (!webview) {
                    return ""
                } else if (webview.webProcessStatus == Oxide.WebView.WebProcessCrashed) {
                    return i18n.tr("The rendering process has closed unexpectedly for this tab")
                } else if (webview.webProcessStatus == Oxide.WebView.WebProcessKilled) {
                    return i18n.tr("The rendering process has been closed for this tab")
                } else {
                    return ""
                }
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(1)

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                wrapMode: Text.Wrap
                text: {
                    if (!webview) {
                        return ""
                    } else if (webview.webProcessStatus == Oxide.WebView.WebProcessCrashed) {
                        return i18n.tr("Something went wrong while displaying this web page")
                    } else if (webview.webProcessStatus == Oxide.WebView.WebProcessKilled) {
                        return i18n.tr("The system is low on memory and can't display this web page.")
                    } else {
                        return ""
                    }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                wrapMode: Text.Wrap
                text: {
                    if (!webview) {
                        return ""
                    } else if (webview.webProcessStatus == Oxide.WebView.WebProcessCrashed) {
                        // TRANSLATORS: %1 is the URL of the page that crashed the renderer process
                        return i18n.tr("%1").arg(webview.url)
                    } else if (webview.webProcessStatus == Oxide.WebView.WebProcessKilled) {
                        return i18n.tr("Try closing unneeded tabs and reloading.")
                    } else {
                        return ""
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)

            Button {
                objectName: "closeTabButton"
                text: i18n.tr("Close tab")
                onClicked: closeTabRequested()
            }

            Button {
                objectName: "reloadButton"
                text: i18n.tr("Reload")
                onClicked: webview.reload()
            }
        }
    }
}
