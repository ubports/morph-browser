/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1
import ".."

Component {
    PopupBase {
        id: downloadDialog
        objectName: "downloadDialog"
        anchors.fill: parent
        property var activeTransfer
        property var downloadId
        property var singleDownload
        property var mimeType
        property var filename
        property var icon: MimeDatabase.iconForMimetype(mimeType)
        property alias contentType: peerPicker.contentType
    
        ContentPeerModel {
            id: peerModel
            handler: ContentHandler.Destination
            contentType: downloadDialog.contentType
        }
    
        Rectangle {
            id: pickerRect
            anchors.fill: parent
            visible: true
            ContentPeerPicker {
                id: peerPicker
                handler: ContentHandler.Destination
                objectName: "contentPeerPicker"
                visible: parent.visible
    
                onPeerSelected: {
                    activeTransfer = peer.request()
                    activeTransfer.downloadId = downloadDialog.downloadId
                    activeTransfer.state = ContentTransfer.Downloading
                    PopupUtils.close(downloadDialog)
                }
    
                onCancelPressed: {
                    PopupUtils.close(downloadDialog)
                }
            }
        }
    }
}
