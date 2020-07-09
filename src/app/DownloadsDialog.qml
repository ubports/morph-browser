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

import QtQuick 2.4
import QtWebEngine 1.5
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtQuick.Controls 2.2 as QQC2
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
    property real preferredHeight:  downloadsDialogColumn.childrenRect.height + units.gu(2)

    contentHeight: preferredHeight > maximumHeight ? maximumHeight : preferredHeight
    contentWidth: preferredWidth > maximumWidth ? maximumWidth : preferredWidth
    
    Loader {
        id: thumbnailLoader
        source: "Thumbnailer.qml"
    }

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
            Layout.preferredHeight: units.gu(10)
            Layout.minimumHeight: label.height
            color: "transparent"
            
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
            
            delegate: ListItem {
                property var download: modelData
                property bool incomplete: !download.isFinished
                property bool error: download.interruptReason > WebEngineDownloadItem.NoReason
                property bool cancelled: download.interruptReason == WebEngineDownloadItem.UserCanceled
                property bool paused: download.isPaused
                readonly property int progress: download ? 100 * (download.receivedBytes / download.totalBytes) : -1
                
                divider.visible: false
                
                onClicked: {
//~                     console.log("error: " + download.interruptReason + " - " + incomplete + " - "  + error )
                    if (!incomplete && !error) {
                        exportPeerPicker.contentType = MimeTypeMapper.mimeTypeToContentType(download.mimeType)
                        contentPicker.open()
                        exportPeerPicker.path = download.path
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
                
                ListItemLayout {
                    title.text: FileUtils.getFilename(modelData.path)
                    subtitle.text: if (cancelled) {
                                        i18n.tr("Cancelled")
                                    } else {
                                        (error ? modelData.interruptReasonString : (incomplete ? i18n.tr("%1%").arg(progress) : i18n.tr("Completed")))
                                        + " - " + FileUtils.formatBytes(download.receivedBytes)
                                    }
                                
                    subtitle.opacity: paused && !cancelled && !error ? 0.5 : 1

                    Item {
                    
                        SlotsLayout.position: SlotsLayout.Leading
                        implicitWidth: units.gu(3)
                        implicitHeight: implicitWidth

                        Image {
                            id: thumbimage
                            
                            asynchronous: true
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: width
                            sourceSize.height: height
                            source: !incomplete && thumbnailLoader.status == Loader.Ready 
                                          && (modelData.mimeType.indexOf("image") === 0 
                                              || modelData.mimeType.indexOf("video") === 0)
                                          ? "image://thumbnailer/file://" + modelData.path : ""
                        }
                        
                        Icon {
                            id: icon
                            
                            visible: thumbimage.status !== Image.Ready
                            anchors.fill: parent
                            name: MimeDatabase.iconForMimetype(modelData.mimeType)
                            color: theme.palette.normal.backgroundText
                        }
                    }
                    
                    Icon {
                        id: iconError

                        implicitWidth: units.gu(4)
                        implicitHeight: implicitWidth
                        SlotsLayout.position: SlotsLayout.Last
                        asynchronous: true
                        name: "dialog-warning-symbolic"
                        visible: error && !cancelled
                        color: theme.palette.normal.negative
                    }

                    Icon {
                        id: iconPauseResume

                        implicitWidth: units.gu(4)
                        implicitHeight: implicitWidth
                        SlotsLayout.position: SlotsLayout.Trailing
                        asynchronous: true
                        name: paused ? "media-preview-start" : "media-preview-pause"
                        visible: incomplete && !error
                        color: theme.palette.normal.backgroundText
                    }
                }
                
                leadingActions: deleteActionList

                ListItemActions {
                    id: deleteActionList
                    actions: [
                        Action {
                            objectName: "leadingAction.remove"
                            iconName: "list-remove"
                            text: i18n.tr("Remove")
                            onTriggered: {
                               downloadsListView.removeItem(index)
                            }
                        },
                        Action {
                            objectName: "leadingAction.cancel"
                            iconName: "cancel"
                            text: i18n.tr("Cancel")
                            enabled: incomplete && !error
                            visible: enabled
                            onTriggered: {
                                if (download) {
                                    download.cancel()
                                    DownloadsModel.cancelDownload(download.id)
                                }
                            }
                        }
                    ]
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
                    downloadsList.splice(0,downloadsList.length)
                    downloadsListView.model = downloadsList
                    downloadsListView.forceLayout()
                }
            }

            Button {
                id: viewButton
                objectName: "downloadsDialog.viewButton"
                anchors.right: parent.right
                text: i18n.tr("View All")
                color: theme.palette.normal.activity
                onClicked: {
                    downloadsDialog.destroy()
                    showDownloadsPage()
                }
            }
        }
    }
}

