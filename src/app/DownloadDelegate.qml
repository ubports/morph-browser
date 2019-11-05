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
import ".."

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
    property bool paused: download.isPaused
    property alias incognito: incognitoIcon.visible

    divider.visible: false

    signal removed()
    signal cancelled()

    height: visible ? layout.height : 0

    SlotsLayout {
        id: layout

        Item {
            SlotsLayout.position: SlotsLayout.Leading
            width: units.gu(3)
            height: units.gu(3)

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

            IndeterminateProgressBar {
                id: progressBar
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: units.gu(0.5)
                visible: incomplete && !error.visible
                progress: downloadDelegate.progress
                // Work around UDM bug #1450144
                indeterminateProgress: progress < 0 || progress > 100
                opacity: paused ? 0.5 : 1
            }
        }

        Column {
            SlotsLayout.position: SlotsLayout.Trailing
            spacing: units.gu(1)
            width: (incomplete && !error.visible) ? cancelButton.width : 0

            Button {
                id: cancelButton
                visible: incomplete && !error.visible
                text: i18n.tr("Cancel")
                onClicked: {
                    if (download) {
                        download.cancel()
                        cancelled()
                    }
                }
            }

            Label {
                visible: !progressBar.indeterminateProgress && incomplete && !error.visible
                width: cancelButton.width
                horizontalAlignment: Text.AlignHCenter
                textSize: Label.Small
                // TRANSLATORS: %1 is the percentage of the download completed so far
                text: i18n.tr("%1%").arg(progressBar.progress)
                opacity: paused ? 0.5 : 1
            }

            Button {
                visible: incomplete && ! paused && ! error.visible
                text: i18n.tr("Pause")
                width: cancelButton.width
                onClicked: {
                    if (download) {
                        download.pause()
                    }
                }
            }

            Button {
                visible: incomplete && paused && ! error.visible
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

    leadingActions: error.visible || !incomplete ? deleteActionList : null

    ListItemActions {
        id: deleteActionList
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                enabled: error.visible || !incomplete
                onTriggered: {

                   cancelled()

                }
            }
        ]
    }
}
