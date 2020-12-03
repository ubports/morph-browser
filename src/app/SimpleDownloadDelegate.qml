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
import QtWebEngine 1.10
import Ubuntu.Components 1.3

ListItem {
    id: simpleDownloadDelegate

    property var download
    property alias title: listItemlayout.title
    property alias subtitle: listItemlayout.subtitle
    property string icon
    property alias image: thumbimage.source

    readonly property bool incomplete: !download.isFinished
    readonly property bool error: download.interruptReason > WebEngineDownloadItem.NoReason
    readonly property bool cancelled: download.interruptReason == WebEngineDownloadItem.UserCanceled
    readonly property bool paused: download.isPaused
    readonly property int progress: download ? 100 * (download.receivedBytes / download.totalBytes) : -1
    
    signal cancel()
    signal remove()
    signal deleted()
    
    divider.visible: false

    MimeData {
        id: linkMimeData
        
        text: download.url
    }
    
    ListItemLayout {
        id: listItemlayout
                    
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
            }
            
            Image {
                asynchronous: true
                anchors.fill: parent
                anchors.margins: units.gu(0.2)
                source: "image://theme/%1".arg(simpleDownloadDelegate.icon || "save")
                visible: thumbimage.status !== Image.Ready
                cache: true
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
    trailingActions: trailingActionList

    ListItemActions {
        id: deleteActionList
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                enabled: error || !incomplete
                visible: enabled
                text: i18n.tr("Delete File")
                onTriggered: {
                   deleted()
                   remove()
                }
            },
            Action {
                objectName: "leadingAction.remove"
                iconName: "list-remove"
                enabled: !incomplete && !error
                visible: enabled
                text: i18n.tr("Remove from List")
                onTriggered: {
                    remove()
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
                        cancel()
                    }
                }
            }
        ]
    }
    
    ListItemActions {
        id: trailingActionList
        actions: [
            Action {
                objectName: "trailingAction.CopyLink"
                iconName: "edit-copy"
                enabled: download.url != "" ? true : false
                visible: enabled
                text: i18n.tr("Copy Download Link")
                onTriggered: {
                   Clipboard.push(linkMimeData)
                }
            }
        ]
    }
}
