/*
 * Copyright 2021 UBports Foundation
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

import "UrlUtils.js" as UrlUtils


Popover {
    id: contentExportDialog

    property alias path: exportPeerPicker.path
    property alias contentType: exportPeerPicker.contentType
    property string mimeType
    property string downloadUrl

    property real maximumWidth: units.gu(70)
    property real preferredWidth: caller ? caller.width * 0.9 : units.gu(40)

    property real maximumHeight: units.gu(80)
    property real preferredHeight: caller ? caller.height > maximumHeight ? caller.height * 0.8 : caller.height - units.gu(5) : units.gu(40)

    signal preview(string url)

    contentHeight: dialogItem.height
    contentWidth: preferredWidth > maximumWidth ? maximumWidth : preferredWidth

    Item {
        id: dialogItem
        height: (preferredHeight > maximumHeight ? maximumHeight : preferredHeight)
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        PageHeader {
            id: header
            title: i18n.tr("Open with")
            anchors {
                top: dialogItem.top
                left: parent.left
                right: parent.right
            }
            
            leadingActionBar.actions: [
                Action {
                    iconName: "close"
                    text: i18n.tr("Close")
                    onTriggered: PopupUtils.close(contentExportDialog)
                }
            ]
            
            trailingActionBar {
                actions: [
                    Action {
                        iconName: "external-link"
                        text: i18n.tr("Open link in browser")
                        visible: (contentExportDialog.downloadUrl !== "") && (contentExportDialog.contentType !== ContentType.Unknown)
                        onTriggered: {
                            PopupUtils.close(contentExportDialog);
                            preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + contentExportDialog.downloadUrl : contentExportDialog.downloadUrl);
                        }
                    },
                    Action {
                        iconName: "document-open"
                        text: i18n.tr("Open file in browser")
                        visible: (contentExportDialog.contentType !== ContentType.Unknown)
                        onTriggered: {
                            PopupUtils.close(contentExportDialog);
                            preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + "file://%1".arg(contentExportDialog.path) : contentExportDialog.path);
                        }
                    }
               ]
            }
        }
        
        Item {
            id: contentPickerItem

            height: (preferredHeight > maximumHeight ? maximumHeight : preferredHeight)  - header.height
            
            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
            }
            
            ContentPeerPicker {
                id: exportPeerPicker
                
                property string path
                focus: visible
                handler: ContentHandler.Destination
                showTitle: false
                
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

    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }
}
