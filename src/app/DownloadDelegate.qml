/*
 * Copyright 2014-2017 Canonical Ltd.
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
import QtQuick.Layouts 1.3
import ".."
import "FileUtils.js" as FileUtils

ListItem {
    id: downloadDelegate
    property string icon
    property alias image: thumbimage.source
    property alias title: title.text
    property alias url: url.text
    property string errorMessage
    property bool incomplete: ! download.isFinished
    property string downloadId
    property var download
    readonly property int progress: download ? 100 * (download.receivedBytes / download.totalBytes) : -1
    property real speed: 0
    property bool paused: download.isPaused
    property alias incognito: incognitoIcon.visible

    divider.visible: false

    signal removed()
    signal cancelled()

    height: visible ? layout.height : 0
    
    Timer {
        id: speedTimer

        property real prevBytes: 0

        interval: 1000
        running: download && !paused? true : false
        repeat: true
        onTriggered: {
            if (download) {
                speed = download.receivedBytes - prevBytes
                prevBytes = download.receivedBytes
            }
        }
    }
    
    MimeData {
        id: linkMimeData
        
        text: model ? model.url : ""
    }

    SlotsLayout {
        id: layout

        ColumnLayout {
            SlotsLayout.position: SlotsLayout.Leading
            spacing: units.gu(1)

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: units.gu(3)
                implicitHeight: units.gu(3)

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
                    source: "image://theme/%1".arg(downloadDelegate.icon || "save")
                    visible: thumbimage.status !== Image.Ready
                    cache: true
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                visible: !progressBar.indeterminateProgress && incomplete
                horizontalAlignment: Text.AlignHCenter
                // TRANSLATORS: %1 is the percentage of the download completed so far
                text: i18n.tr("%1%").arg(progressBar.progress)
                opacity: paused ? 0.5 : 1
            }
        }

        mainSlot: Column {
            Label {
                id: title
                textSize: Label.Small
                color: theme.palette.normal.overlayText
                elide: Text.ElideRight
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Label {
                id: url
                textSize: Label.Small
                color: theme.palette.normal.overlayText
                elide: Text.ElideRight
                anchors {
                    left: parent.left
                    right: parent.right
                }
            }

            Item {
                height: error.visible ? units.gu(1) : units.gu(2)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: incomplete
            }

            Item {
                id: error
                visible: (incomplete && (download === undefined)) || errorMessage
                height: units.gu(3)
                anchors {
                    left: parent.left
                    right: parent.right
                }

                Icon {
                    id: errorIcon
                    width: units.gu(2)
                    height: units.gu(2)
                    anchors.verticalCenter: parent.verticalCenter
                    name: "dialog-warning-symbolic"
                    color: theme.palette.normal.negative
                }

                Label {
                    anchors {
                        left: errorIcon.right
                        leftMargin: units.gu(1)
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    textSize: Label.Small
                    color: theme.palette.normal.negative
                    text: errorMessage ||
                          ((incomplete && download === undefined) ? i18n.tr("Download failed") : "")
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                visible: incomplete && !error.visible
                anchors {
                    left: parent.left
                    right: parent.right
                }

                IndeterminateProgressBar {
                    id: progressBar
                    Layout.fillWidth: true
                    implicitHeight: units.gu(0.5)
                    progress: downloadDelegate.progress
                    // Work around UDM bug #1450144
                    indeterminateProgress: progress < 0 || progress > 100
                    opacity: paused ? 0.5 : 1
                }

                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: units.gu(4)

                    Label {
                        horizontalAlignment: Text.AlignHCenter
                        textSize: Label.Small
                        text: download ? FileUtils.formatBytes(download.receivedBytes) + " / " + FileUtils.formatBytes(download.totalBytes) : i18n.tr("Unknown")
                        opacity: paused ? 0.5 : 1
                    }

                    Label {
                        horizontalAlignment: Text.AlignHCenter
                        textSize: Label.Small
                        // TRANSLATORS: %1 is the number of bytes i.e. 2bytes, 5KB, 1MB
                        text: "(" + i18n.tr("%1/s").arg(FileUtils.formatBytes(downloadDelegate.speed)) + ")"
                        opacity: paused ? 0.5 : 1
                    }
                }
            }
        }
        Icon {
            id: iconPauseResume

            implicitWidth: units.gu(4)
            implicitHeight: implicitWidth
            SlotsLayout.position: SlotsLayout.Trailing
            asynchronous: true
            name: paused ? "media-preview-start" : "media-preview-pause"
            visible: incomplete && !error.visible
            color: theme.palette.normal.overlayText
        }
    }

    Icon {
        id: incognitoIcon
        anchors {
            right: parent.right
            rightMargin: units.gu(2)
            bottom: parent.bottom
            bottomMargin: units.gu(1)
        }
        width: units.gu(2)
        height: units.gu(2)
        asynchronous: true
        name: "private-browsing"
    }

    leadingActions: deleteActionList
    trailingActions: trailingActionList

    ListItemActions {
        id: deleteActionList
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                enabled: error.visible || !incomplete
                visible: enabled
                text: i18n.tr("Delete File")
                onTriggered: {
                   removed()
                }
            },
            Action {
                objectName: "leadingAction.remove"
                iconName: "list-remove"
                enabled: !incomplete && !error.visible
                visible: enabled
                text: i18n.tr("Remove from History")
                onTriggered: {
                   removed()
                }
            },
            Action {
                objectName: "leadingAction.cancel"
                iconName: "cancel"
                enabled: incomplete && !error.visible
                visible: enabled
                text: i18n.tr("Cancel")
                onTriggered: {
                    if (download) {
                        download.cancel()
                        cancelled()
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
                enabled: model.url != "" ? true : false
                visible: enabled
                text: i18n.tr("Copy Download Link")
                onTriggered: {
                   Clipboard.push(linkMimeData)
                }
            }
        ]
    }
}
