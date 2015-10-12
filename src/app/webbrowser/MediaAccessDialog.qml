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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import "../UrlUtils.js" as UrlUtils

Dialog {
    id: dialog

    property var request
    modal: true

    title: request.isForAudio && request.isForVideo ?
           i18n.tr("Allow this domain to access your camera and microphone?") :
           (request.isForVideo ? i18n.tr("Allow this domain to access your camera?")
                               : i18n.tr("Allow this domain to access your microphone?"))

    text: request.embedder.toString() !== request.origin.toString() ?
          internal.textWhenEmbedded : request.origin

    Row {
        id: internal

        // TRANSLATORS: %1 refers to the origin requesting access and %2 refers to the origin that embeds it
        readonly property string textWhenEmbedded: i18n.tr("%1 (embedded in %2)")
                                                   .arg(request.origin).arg(request.embedder)
        height: units.gu(4)
        spacing: units.gu(2)
        anchors.horizontalCenter: parent.horizontalCenter

        Button {
            id: allowButton
            objectName: "mediaAccessDialog.allowButton"
            text: i18n.tr("Yes")
            color: UbuntuColors.green
            width: units.gu(14)
            onClicked: {
                request.allow()
                hide()
            }
        }

        Button {
            id: denyButton
            objectName: "mediaAccessDialog.denyButton"
            text: i18n.tr("No")
            color: UbuntuColors.red
            width: units.gu(14)
            onClicked: {
                request.deny()
                hide()
            }
        }
    }
}
