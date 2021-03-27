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
import Ubuntu.Content 1.3
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Controls.Suru 2.2

import "UrlUtils.js" as UrlUtils

QQC2.Dialog {
    id: contentExportDialog

    objectName: "contentExportDialog"

    property alias path: exportPeerPicker.path
    property alias contentType: exportPeerPicker.contentType
    property string mimeType
    property string downloadUrl
    property string fileName

    property real maximumWidth: units.gu(90)
    property real preferredWidth: parent.width

    property real maximumHeight: units.gu(80)
    property real preferredHeight: parent.height > maximumHeight ? parent.height * 0.7 : parent.height

    signal preview(string url)

    width: preferredWidth > maximumWidth ? maximumWidth : preferredWidth
    height: preferredHeight > maximumHeight ? maximumHeight : preferredHeight
    x: (parent.width - width) / 2
    parent: QQC2.Overlay.overlay
    topPadding: units.gu(0.2)
    leftPadding: units.gu(0.2)
    rightPadding: units.gu(0.2)
    bottomPadding: units.gu(0.2)
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
    modal: true

    QQC2.Overlay.modal: Rectangle {
        color: Suru.overlayColor
        Behavior on opacity { NumberAnimation { duration: Suru.animations.FastDuration } }
    }

    function openDialog(_downloadPath, _contentType, _mimeType, _downloadURL, _fileName){
        path = _downloadPath
        contentType = _contentType
        mimeType = _mimeType
        downloadUrl = _downloadURL
        fileName = _fileName
        y = Qt.binding(function(){return parent.width >= units.gu(90) ? (parent.height - height) / 2 : (parent.height - height)})
        open()
    }

    Item {
        anchors.fill: parent

        PageHeader {
            id: header

            title: i18n.tr("Open with")
            subtitle: i18n.tr("File name: %1").arg(contentExportDialog.fileName)

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            leadingActionBar.actions: [
                Action {
                    iconName: "close"
                    text: i18n.tr("Close")
                    onTriggered: contentExportDialog.close()
                }
            ]

            trailingActionBar {
                actions: [
                    Action {
                        iconName: "external-link"
                        text: i18n.tr("Open link in browser")
                        visible: (contentExportDialog.downloadUrl !== "") && (contentExportDialog.contentType !== ContentType.Unknown)
                        onTriggered: {
                            contentExportDialog.close()
                            preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + contentExportDialog.downloadUrl : contentExportDialog.downloadUrl);
                        }
                    },
                    Action {
                        iconName: "document-open"
                        text: i18n.tr("Open file in browser")
                        visible: (contentExportDialog.contentType !== ContentType.Unknown)
                        onTriggered: {
                            contentExportDialog.close()
                            preview((contentExportDialog.mimeType === "application/pdf") ? UrlUtils.getPdfViewerExtensionUrlPrefix() + "file://%1".arg(contentExportDialog.path) : contentExportDialog.path);
                        }
                    }
               ]
            }
        }

        Item {
            id: contentPickerItem

            anchors {
                top: header.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
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
                    contentExportDialog.close()
                }
                onCancelPressed: contentExportDialog.close()
                Keys.onEscapePressed: contentExportDialog.close()
            }
        }
    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }
}
