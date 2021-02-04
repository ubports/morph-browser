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
import QtWebEngine 1.10
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.Layouts 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

import "MimeTypeMapper.js" as MimeTypeMapper
import "FileUtils.js" as FileUtils

Popover {
    id: downloadsDialog

    property var downloadsList: []
    property bool isEmpty: downloadsListView.count === 0
    readonly property real controlsHeight: (downloadsDialogColumn.spacing * (downloadsDialogColumn.children.length - 1)) 
                                            + (downloadsDialogColumn.anchors.margins * 2) + buttonsBar.height + titleLabel.height
    property real maximumWidth: units.gu(60)
    property real preferredWidth: browser.width - units.gu(6)
    
    property real maximumHeight: browser.height - units.gu(6)
    property real preferredHeight:  downloadsDialogColumn.height + units.gu(2)
    
    signal showDownloadsPage()
    signal preview(string url)

    contentHeight: preferredHeight > maximumHeight ? maximumHeight : preferredHeight
    contentWidth: preferredWidth > maximumWidth ? maximumWidth : preferredWidth
    
    grabDismissAreaEvents: true

    ColumnLayout {
        id: downloadsDialogColumn
        
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: units.gu(1)
        }

        spacing: units.gu(2)

        Label {
            id: titleLabel

            Layout.fillWidth: true
            font.bold: true
            text: i18n.tr("Recent Downloads")
        }
        
        Rectangle {
            id: emptyLabel
            
            visible: isEmpty
            color: "transparent"

            Layout.preferredHeight: units.gu(10)
            Layout.minimumHeight: label.height
            Layout.fillWidth: true
            
            Label {
                id: label
                text: i18n.tr("No Recent Downloads")
                anchors.centerIn: parent
            }
        }

        ListView {
            id: downloadsListView
            
            visible: !isEmpty
            Layout.fillWidth: true
            Layout.preferredHeight: downloadsListView.count * units.gu(7)
            Layout.maximumHeight: browser.height - controlsHeight - units.gu(7)
            Layout.minimumHeight: units.gu(7)
            clip: true

            model: downloadsList

            property int selectedIndex: -1
            
            delegate: SimpleDownloadDelegate {
                download: modelData
                title.text: FileUtils.getFilename(modelData.path)
                subtitle.text: if (cancelled) {
                            i18n.tr("Cancelled")
                        } else {
                            // TRANSLATORS: %1 is the percentage of the download completed so far
                            (error ? modelData.interruptReasonString : (incomplete ? i18n.tr("%1%").arg(progress) : i18n.tr("Completed")))
                            + " - " + FileUtils.formatBytes(download.receivedBytes)
                        }
                        
                image: !incomplete && thumbnailLoader.status == Loader.Ready 
                              && (modelData.mimeType.indexOf("image") === 0 
                                  || modelData.mimeType.indexOf("video") === 0)
                              ? "image://thumbnailer/file://" + modelData.path : ""
                icon: MimeDatabase.iconForMimetype(modelData.mimeType)
                
                onClicked: {
                    if (!incomplete && !error) {
                        var properties = {"path": download.path, "contentType": MimeTypeMapper.mimeTypeToContentType(download.mimeType), "mimeType": download.mimeType, "downloadUrl": download.url}
                        var exportDialog = PopupUtils.open(Qt.resolvedUrl("ContentExportDialog.qml"), downloadsDialog.parent, properties)
                        exportDialog.preview.connect(downloadsDialog.preview)
                    } else {
                        if (download) {
                            if (paused) {
                                download.resume()
                            } else {
                                download.pause()
                            }
                        }
                    }
                }
                
                onRemove: downloadsListView.removeItem(index)
                onCancel: DownloadsModel.cancelDownload(download.id)
                onDeleted: {
                    if (!incomplete) {
                        DownloadsModel.deleteDownload(download.path)
                    }
                }
            }

            Keys.onDeletePressed: {
                currentItem.removeItem(currentItem.download)
            }
            
            function removeItem(index) {
                downloadsList.splice(index, 1);
                model = downloadsList
                forceLayout()
            }
            
            function clear() {
                downloadsList.splice(0, downloadsList.length);
                model = downloadsList
                forceLayout()
            }
        }
        
        Item {
            id: buttonsBar

            Layout.fillWidth: true
            implicitHeight: clearButton.height

            Button {
                id: clearButton
                visible: !isEmpty
                objectName: "downloadsDialog.clearButton"
                text: i18n.tr("Clear")
                onClicked: {
                    downloadsListView.clear()
                }
            }

            Button {
                id: viewButton
                objectName: "downloadsDialog.viewButton"
                anchors.right: parent.right
                text: i18n.tr("View All")
                color: theme.palette.normal.activity
                onClicked: {
                    showDownloadsPage()
                    downloadsDialog.destroy()
                }
            }
        }
    }
    
    Loader {
        id: thumbnailLoader
        source: "Thumbnailer.qml"
    }
}
