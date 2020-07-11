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


import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3


Popover {
    id: contentExportDialog

    property alias path: exportPeerPicker.path
    property alias contentType: exportPeerPicker.contentType
    
    property real maximumWidth: units.gu(50)
    property real preferredWidth: caller ? caller.width * 0.9 : units.gu(40)
    
    property real maximumHeight: units.gu(60)
    property real preferredHeight: caller.height > maximumHeight ? caller.height * 0.8 : caller.height - units.gu(5)
    
    contentHeight: exportPeerPicker.height
    contentWidth: preferredWidth > maximumWidth ? maximumWidth : preferredWidth

    Item {
        height: preferredHeight > maximumHeight ? maximumHeight : preferredHeight
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        
        ContentPeerPicker {
            id: exportPeerPicker
            
            property string path
            focus: visible
            anchors.fill: parent
            handler: ContentHandler.Destination
            
            onPeerSelected: {
                var transfer = peer.request()
                if (transfer.state === ContentTransfer.InProgress) {
                    transfer.items = [contentItemComponent.createObject(contentExportDialog, {"url": path})]
                    transfer.state = ContentTransfer.Charged
                }
                PopupUtils.close(contentExportDialog)
            }
            onCancelPressed: PopupUtils.close(contentExportDialog)
            Keys.onEscapePressed: PopupUtils.close(contentExportDialog)
        }
        
        
    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }
}
