/*
 * Copyright 2014-2016 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import ".."

ListItem {
    id: downloadDelegate

    property var downloadManager

    property alias icon: mimeicon.name
    property alias image: thumbimage.source
    property alias title: title.text
    property alias url: url.text
    property string errorMessage
    property bool incomplete: false
    property string downloadId
    property var download
    property int progress: download ? download.progress : 0
    property bool paused

    divider.visible: false

    signal removed()
    signal cancelled()

    height: visible ? (incomplete ? (paused ? units.gu(13) : units.gu(10)) : units.gu(7)) : 0

    QtObject {
        id: internal

        function connectToDownloadObject() {
            if (incomplete && !download && downloadManager) {
                for(var i = 0; i < downloadManager.downloads.length; i++) {
                    if (downloadManager.downloads[i].downloadId == downloadId) {
                        download = downloadManager.downloads[i]
                    }
                }
            }
        }
    }

    Component.onCompleted: internal.connectToDownloadObject()
    onDownloadManagerChanged: internal.connectToDownloadObject()

    Item {
        
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }

        Item {
            id: iconContainer
            width: units.gu(3)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: downloadDelegate.incomplete ? -units.gu(1) : 0

            Image {
                id: thumbimage
                asynchronous: true
                width: parent.width
                height: parent.height
                fillMode: Image.PreserveAspectFit
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                anchors.verticalCenter: parent.verticalCenter
            }

            Image {
                id: mimeicon
                asynchronous: true
                anchors.fill: parent
                anchors.margins: units.gu(0.2)
                source: "image://theme/%1".arg(name != "" ? name : "save")
                visible: thumbimage.status !== Image.Ready
                cache: true
                property string name
            }
        }

        Item {
            anchors.top: iconContainer.top
            anchors.left: iconContainer.right
            anchors.leftMargin: units.gu(2)
            anchors.right: parent.right

            Column {
                id: detailsColumn
                width: parent.width - cancelColumn.width
                height: parent.height

                Label {
                    id: title
                    fontSize: "x-small"
                    color: "#5d5d5d"
                    elide: Text.ElideRight
                    width: parent.width
                }

                Label {
                    id: url
                    fontSize: "x-small"
                    color: "#5d5d5d"
                    elide: Text.ElideRight
                    width: parent.width
                }

                Item {
                    height: error.visible ? units.gu(1) : units.gu(2)
                    width: parent.width
                    visible: downloadDelegate.incomplete
                }

                Item {
                    id: error
                    visible: incomplete && download === undefined || errorMessage !== ""
                    height: units.gu(3)
                    width: parent.width

                    Icon {
                        id: errorIcon
                        width: units.gu(2)
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        name: "dialog-warning-symbolic"
                        color: theme.palette.normal.negative
                    }

                    Label {
                        width: parent.width - errorIcon.width
                        anchors.left: errorIcon.right
                        anchors.leftMargin: units.gu(1)
                        anchors.verticalCenter: errorIcon.verticalCenter
                        fontSize: "x-small"
                        color: theme.palette.normal.negative
                        text: errorMessage !== "" ? errorMessage 
                                                  : (incomplete && download === undefined) ? i18n.tr("Download failed") 
                                                                                           : ""
                        elide: Text.ElideRight
                    }
                }

                IndeterminateProgressBar {
                    id: progressBar
                    width: parent.width
                    height: units.gu(0.5)
                    visible: downloadDelegate.incomplete && !error.visible
                    progress: downloadDelegate.progress
                    // Work around UDM bug #1450144
                    indeterminateProgress: downloadDelegate.progress < 0 || downloadDelegate.progress > 100
                }
            }

            Column {
                id: cancelColumn
                spacing: units.gu(1)
                anchors.top: detailsColumn.top
                anchors.left: detailsColumn.right
                anchors.leftMargin: units.gu(2)
                width: downloadDelegate.incomplete && !error.visible ? cancelButton.width + units.gu(2) : 0

                Button {
                    visible: downloadDelegate.incomplete && !error.visible
                    id: cancelButton
                    text: i18n.tr("Cancel")
                    onClicked: {
                        if (download) {
                            download.cancel()
                            cancelled()
                        }
                    }
                }

                Label {
                    visible: !progressBar.indeterminateProgress && downloadDelegate.incomplete
                                                                && !error.visible 
                                                                && !downloadDelegate.paused
                    width: cancelButton.width
                    horizontalAlignment: Text.AlignHCenter
                    fontSize: "x-small"
                    text: progressBar.progress + "%"
                }

                Button {
                    visible: downloadDelegate.paused
                    text: i18n.tr("Resume")
                    width: cancelButton.width
                    onClicked: {
                        if (download) {
                            download.resume()
                        }
                    }
                }
            }

        }
    }

    leadingActions: error.visible || !downloadDelegate.incomplete ? deleteActionList : null

    ListItemActions {
        id: deleteActionList
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                enabled: error.visible || !downloadDelegate.incomplete
                onTriggered: error.visible ? downloadDelegate.cancelled() 
                                           : downloadDelegate.removed()
            }
        ]
    }
}
