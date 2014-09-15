/*
 * Copyright 2013-2014 Canonical Ltd.
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

Rectangle {
    property var certificateError

    signal allowed()
    signal denied()

    Connections {
        target: certificateError ? certificateError : null
        onCancelled: {
            denied()
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(4)

        spacing: units.gu(3)

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "security-alert"
            width: units.gu(4)
            height: width
        }

        Label {
            width: parent.width
            // TRANSLATORS: %1 refers to the domain name of the SSL certificate
            text: i18n.tr("This site security certificate is not trusted\nYou attempted to reach %1 but the server presented a security certificate issued by an entity that is not trusted.").arg(certificateError ? certificateError.url : "")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            fontSize: "x-small"
        }

        Label {
            width: parent.width
            text: i18n.tr("Learn more")
            font.underline: true
            fontSize: "x-small"
            horizontalAlignment: Text.AlignHCenter
            visible: !moreInfo.visible
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    moreInfo.visible = true
                }
            }
        }

        Column {
            id: moreInfo
            width: parent.width
            visible: false

            Label {
                fontSize: "x-small"

            }
        }

        Label {
            width: parent.width
            text: i18n.tr("You should not proceed, especially if you have never seen this warning before for this site")
            wrapMode: Text.Wrap
            fontSize: "x-small"
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            width: parent.width
            height: backButton.height
            Button {
                anchors.left: parent.left
                text: i18n.tr("Proceed anyway")
                visible: certificateError ? certificateError.overridable : false
                width: units.gu(16)
                onClicked: {
                    certificateError.allow()
                    allowed()
                }
            }

            Button {
                id: backButton
                anchors.right: parent.right
                text: i18n.tr("Back to safety")
                width: units.gu(16)
                onClicked: {
                    certificateError.deny()
                    denied()
                }
                color: UbuntuColors.orange
            }
        }
    }
}
