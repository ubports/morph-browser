/*
 * Copyright 2015-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Rectangle {
    property var webview

    signal closeTabRequested()

    Column {
        anchors {
            fill: parent
            margins: units.gu(4)
        }
        spacing: units.gu(4)

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "assets/tab-error.png"
        }

        Label {
            anchors {
                left: parent.left
                right: parent.right
            }

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            text: webview ? i18n.tr("The rendering process has been closed for this tab.") : ""
        }

        Label {
            anchors {
                left: parent.left
                right: parent.right
            }

            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.weight: Font.Light
            text: {
                return i18n.tr("Something went wrong while displaying %1.").arg(webview.url)
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
                color: theme.palette.normal.positive
                onClicked: webview.reload()
            }
        }
    }
}
