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

import QtQuick 2.0
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Thumbnailer 0.1
import Ubuntu.Content 1.0
import Ubuntu.Web 0.2
import webbrowserapp.private 0.1

import "urlManagement.js" as UrlManagement
import "../MimeTypeMapper.js" as MimeTypeMapper

Item {
    id: downloadsItem

    property QtObject downloadsModel
    property Settings settingsObject
    property var activeTransfer
    property bool selectionMode: false

    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    BrowserPageHeader {
        id: title

        onBack: downloadsItem.done()
        text: i18n.tr("Downloads")
    }

    ListView {
        id: downloadsListView

        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            rightMargin: units.gu(2)
        }

        model: downloadsModel

        delegate: DownloadDelegate {
            title: model.filename
            url: model.url
            image: model.mimetype.indexOf("image") === 0 || model.mimetype.indexOf("video") === 0 ? "image://thumbnailer/file://" + model.path : ""
            extension: downloadsModel.iconForMimetype(model.mimetype) === "-x-generic" ? model.extension : ""
            icon: downloadsModel.iconForMimetype(model.mimetype) !== "-x-generic" ? downloadsModel.iconForMimetype(model.mimetype) : ""

            onClicked: {
                exportPeerPicker.contentType = MimeTypeMapper.mimeTypeToContentType(model.mimetype)
                exportPeerPicker.visible = true
                exportPeerPicker.path = model.path
            }
        }

    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }

    ContentPeerPicker {
        id: exportPeerPicker
        visible: false
        anchors.fill: parent
        handler: ContentHandler.Destination
        property string path
        onPeerSelected: {
            var transfer = peer.request()
            if (transfer.state === ContentTransfer.InProgress) {
                transfer.items = [contentItemComponent.createObject(downloadsItem, {"url": path})]
                transfer.state = ContentTransfer.Charged
            }
            visible = false
        }
        onCancelPressed: {
            visible = false
        }
    }

}
