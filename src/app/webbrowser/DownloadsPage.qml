/*
 * Copyright 2015-2016 Canonical Ltd.
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
import Ubuntu.Content 1.3
import webbrowserapp.private 0.1
import webbrowsercommon.private 0.1

import "../MimeTypeMapper.js" as MimeTypeMapper

FocusScope {
    id: downloadsItem

    property var downloadManager

    // We can get file picking requests either via content-hub (activeTransfer)
    // Or via the internal oxide file picker (internalFilePicker) in the case
    // where the user wishes to upload a file from their previous downloads.
    property var activeTransfer
    property var internalFilePicker

    property bool selectMode
    property bool pickingMode
    property bool multiSelect
    property alias mimetypeFilter: downloadModelFilter.pattern

    signal done()

    Loader {
        id: thumbnailLoader
        source: "Thumbnailer.qml"
    }

    Rectangle {
        anchors.fill: parent
        color: "#fbfbfb"
    }

    BrowserPageHeader {
        id: title
        text: i18n.tr("Downloads")
        color: "#f7f7f7"
        actions: [
            Action {
                text: i18n.tr("Confirm selection")
                iconName: "tick"
                visible: pickingMode
                enabled: downloadsListView.ViewItems.selectedIndices.length > 0
                onTriggered: {
                    var results = []
                    if (internalFilePicker) {
                        for (var i = 0; i < downloadsListView.ViewItems.selectedIndices.length; i++) {
                            var selectedDownload = downloadsListView.model.get(downloadsListView.ViewItems.selectedIndices[i])
                            results.push(selectedDownload.path)
                        }
                        internalFilePicker.accept(results)
                    } else {
                        for (var i = 0; i < downloadsListView.ViewItems.selectedIndices.length; i++) {
                            var selectedDownload = downloadsListView.model.get(downloadsListView.ViewItems.selectedIndices[i])
                            results.push(resultComponent.createObject(downloadsItem, {"url": "file://" + selectedDownload.path}))
                        }
                        activeTransfer.items = results
                        activeTransfer.state = ContentTransfer.Charged
                    }
                    downloadsItem.done()
                }
            },
            Action {
                text: i18n.tr("Select all")
                iconName: "select"
                visible: selectMode
                onTriggered: {
                    if (downloadsListView.ViewItems.selectedIndices.length === downloadsListView.count) {
                        downloadsListView.ViewItems.selectedIndices = []
                    } else {
                        var indices = []
                        for (var i = 0; i < downloadsListView.count; ++i) {
                            indices.push(i)
                        }
                        downloadsListView.ViewItems.selectedIndices = indices
                    }
                }
            },
            Action {
                text: i18n.tr("Delete")
                iconName: "delete"
                visible: selectMode
                enabled: downloadsListView.ViewItems.selectedIndices.length > 0
                onTriggered: {
                    var toDelete = []
                    for (var i = 0; i < downloadsListView.ViewItems.selectedIndices.length; i++) {
                        var selectedDownload = downloadsListView.model.get(downloadsListView.ViewItems.selectedIndices[i])
                        toDelete.push(selectedDownload.path)
                    }
                    for (var i = 0; i < toDelete.length; i++) {
                        DownloadsModel.deleteDownload(toDelete[i])
                    }
                    downloadsListView.ViewItems.selectedIndices = []
                    downloadsItem.selectMode = false
                }
            },
            Action {
                iconName: "edit" 
                visible: !selectMode && !pickingMode
                enabled: downloadsListView.count > 0
                onTriggered: {
                    selectMode = true
                    multiSelect = true
                }
            }
        ]
        onBack: {
            if (selectMode) {
                selectMode = false
            } else {
                if (activeTransfer) {
                    activeTransfer.state = ContentTransfer.Aborted
                }
                if (internalFilePicker) {
                    internalFilePicker.reject()
                }
                downloadsItem.done()
            }
        }
    }

    Component {
        id: resultComponent
        ContentItem { }
    }

    ListView {
        id: downloadsListView
        clip: true
        focus: !exportPeerPicker.focus

        anchors {
            fill: parent
            topMargin: title.height
        }

        model: SortFilterModel {
            model: DownloadsModel
            filter { 
                id: downloadModelFilter
                property: "mimetype"
            }
        }

        delegate: DownloadDelegate {
            downloadManager: downloadsItem.downloadManager
            downloadId: model.downloadId
            title: model.filename ? model.filename : model.url.toString().split('/').pop().split('?').shift()
            url: model.url
            image: model.complete && thumbnailLoader.status == Loader.Ready 
                                  && (model.mimetype.indexOf("image") === 0 
                                      || model.mimetype.indexOf("video") === 0)
                                  ? "image://thumbnailer/file://" + model.path : ""
            icon: MimeDatabase.iconForMimetype(model.mimetype)
            incomplete: !model.complete
            selectMode: downloadsItem.selectMode || downloadsItem.pickingMode
            visible: !(selectMode && incomplete)
            errorMessage: model.error
            paused: model.paused
            // Work around bug #1493880
            property bool lastSelected

            onSelectedChanged: {
                if (!multiSelect && selected && lastSelected != selected) {
                    downloadsListView.ViewItems.selectedIndices = [index]
                }
                lastSelected = selected
            }

            onClicked: {
                if (model.complete) {
                    if (selectMode) {
                        selected = !selected
                    } else {
                        exportPeerPicker.contentType = MimeTypeMapper.mimeTypeToContentType(model.mimetype)
                        exportPeerPicker.visible = true
                        exportPeerPicker.path = model.path
                    }
                }
            }

            onPressAndHold: {
                downloadsItem.selectMode = true
                downloadsItem.multiSelect = true
                if (downloadsItem.selectMode) {
                    downloadsListView.ViewItems.selectedIndices = [index]
                }
            }

            onRemoved: {
                if (model.complete) {
                    DownloadsModel.deleteDownload(model.path)
                }
            }

            onCancelled: {
                DownloadsModel.cancelDownload(model.downloadId)
            }
        }

        highlight: ListViewHighlight {}

        Keys.onEnterPressed: currentItem.clicked()
        Keys.onReturnPressed: currentItem.clicked()
        Keys.onEscapePressed: {
            if (selectMode) {
                selectMode = false
            } else {
                event.accepted = false
            }
        }
        Keys.onSpacePressed: {
            if (selectMode || pickingMode) {
                currentItem.clicked()
            }
        }
        Keys.onDeletePressed: {
            if (!selectMode && !pickingMode) {
                currentItem.removed()
            }
        }
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: downloadsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No downloads available")
    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }

    ContentPeerPicker {
        id: exportPeerPicker
        visible: false
        focus: visible
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
        onCancelPressed: visible = false
        Keys.onEscapePressed: visible = false
    }

}
