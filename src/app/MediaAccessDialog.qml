/*
 * Copyright 2015-2016 Canonical Ltd.
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

Dialog {
    property var request
    modal: true

    Label {
        elide: Text.ElideRight
        textSize: Label.Large
        color: theme.palette.normal.overlayText
        text: i18n.tr("Permission")
    }

    Label {
        color: theme.palette.normal.baseText
        wrapMode: Text.Wrap
        text: (request.isForAudio && request.isForVideo)
                  ? i18n.tr("Allow this domain to access your camera and microphone?")
                  : (request.isForVideo ? i18n.tr("Allow this domain to access your camera?")
                                        : i18n.tr("Allow this domain to access your microphone?"))
    }

    Label {
        color: theme.palette.normal.baseText
        wrapMode: Text.Wrap
        text: (request.embedder.toString() !== request.origin.toString())
                  // TRANSLATORS: %1 is the URL of the site requesting access to camera and/or microphone and %2 is the URL of the site that embeds it
                  ? i18n.tr("%1 (embedded in %2)").arg(request.origin).arg(request.embedder)
                  : request.origin
    }

    Item {
        height: units.gu(2)
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)
            color: theme.palette.normal.base
        }
    }

    Row {
        height: units.gu(4)
        spacing: units.gu(2)
        layoutDirection: Qt.RightToLeft

        Button {
            objectName: "mediaAccessDialog.allowButton"
            text: i18n.tr("Yes")
            color: UbuntuColors.green
            width: units.gu(10)
            onClicked: {
                request.allow()
                hide()
            }
        }

        Button {
            objectName: "mediaAccessDialog.denyButton"
            text: i18n.tr("No")
            color: UbuntuColors.lightGrey
            width: units.gu(10)
            onClicked: {
                request.deny()
                hide()
            }
        }
    }

    // adjust default dialog visuals to custom design requirements
    // (should not be needed when updated dialog implementation lands in UITK)
    Binding {
        target: __foreground
        property: "margins"
        value: units.gu(2)
    }
}
