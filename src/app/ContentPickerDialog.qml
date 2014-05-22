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
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1 as Popups
import Ubuntu.Content 0.1
import "MimeTypeMapping.js" as MimeTypeMapper

Component {
    Popups.PopupBase {
        id: picker
        property var activeTransfer
        property var selectedItems
    
        Rectangle {
            anchors.fill: parent
    
            ContentTransferHint {
                anchors.fill: parent
                activeTransfer: picker.activeTransfer
            }
    
            ContentPeerPicker {
                id: peerPicker
                anchors.fill: parent
                visible: true
                contentType: ContentType.All
                handler: ContentHandler.Source
    
                onPeerSelected: {
                    if (model.allowMultipleFiles) {
                        peer.selectionType = ContentTransfer.Multiple
                    } else {
                        peer.selectionType = ContentTransfer.Single
                    }
                    picker.activeTransfer = peer.request()
                    stateChangeConnection.target = picker.activeTransfer
                }
    
                onCancelPressed: {
                    webview.focus = true
                    model.reject()
                }
            }
        }
    
        Connections {
            id: stateChangeConnection
            onStateChanged: {
                if (picker.activeTransfer.state === ContentTransfer.Charged) {
                    selectedItems = []
                    for(var i in picker.activeTransfer.items) {
                        selectedItems.push(String(picker.activeTransfer.items[i].url).replace("file://", ""))
                    }
                    acceptTimer.running = true
                }
            }
        }
    
        // FIXME: Work around for browser becoming insensitive to touch events
        // if the dialog is dismissed while the application is inactive.
        // Just listening for changes to Qt.application.active doesn't appear
        // to be enough to resolve this, so it seems that something else needs
        // to be happening first. As such there's a potential for a race
        // condition here, although as yet no problem has been encountered.
        Timer {
            id: acceptTimer
            interval: 100
            repeat: true
            onTriggered: {
                if(Qt.application.active) {
                    webview.focus = true
                    model.accept(selectedItems)
                }
            }
        }
    
        Component.onCompleted: {
            if(acceptTypes.length === 1) {
                peerPicker.contentType = MimeTypeMapper.mimeTypeToContentType(acceptTypes[0]);
            } else {
                peerPicker.contentType = ContentType.All
            }
            show()
        }
    
    }
}
