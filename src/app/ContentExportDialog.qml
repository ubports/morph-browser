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

    contentHeight: exportPeerPicker.height + openInBrowserRow.height
    contentWidth: preferredWidth > maximumWidth ? maximumWidth : preferredWidth

    Item {
        id: dialogItem
        height: (preferredHeight > maximumHeight ? maximumHeight : preferredHeight) - openInBrowserRow.height
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        
        ContentPeerPicker {
            id: exportPeerPicker
            
            property string path
            focus: visible
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
        
        Row {
            id: openInBrowserRow
            anchors.top: dialogItem.bottom
            anchors.right: parent.right
            spacing: units.gu(1)
            padding: units.gu(1)

        Label {
            id: labelOpenInBrowser
            visible: openFileInBrowser.visible || openLinkInBrowser.visible
            text: i18n.tr("Open in browser")
            anchors.verticalCenter: parent.verticalCenter
        }
        IconLink {
            id: openFileInBrowser
            height: units.gu(3)
            width: height
            visible: (contentExportDialog.contentType !== ContentType.Unknown)
            name: "document-open"
            onClicked: {
                PopupUtils.close(contentExportDialog);
                preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + "file://%1".arg(contentExportDialog.path) : contentExportDialog.path);
            }
        }
        IconLink {
            id: openLinkInBrowser
            height: units.gu(3)
            width: height
            visible: (contentExportDialog.downloadUrl !== "") && (contentExportDialog.contentType !== ContentType.Unknown)
            name: "external-link"
            onClicked: {
                PopupUtils.close(contentExportDialog);
                preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + contentExportDialog.downloadUrl : contentExportDialog.downloadUrl);
            }
        }
        
        }

    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }
}
