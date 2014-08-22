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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Content 0.1

PopupBase {
    id: shareDialog
    anchors.fill: parent
    property var activeTransfer
    property var items: []
    property alias contentType: peerPicker.contentType

    Rectangle {
        anchors.fill: parent
        ContentPeerPicker {
            id: peerPicker
            handler: ContentHandler.Share
            visible: parent.visible

            onPeerSelected: {
                activeTransfer = peer.request()
                activeTransfer.items = shareDialog.items
                activeTransfer.state = ContentTransfer.Charged
                PopupUtils.close(shareDialog)
            }

            onCancelPressed: {
                PopupUtils.close(shareDialog)
            }
        }
    }
}
