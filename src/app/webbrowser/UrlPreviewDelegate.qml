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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import webbrowserapp.private 0.1
import ".."
import "."

AbstractButton {
    id: preview

    property url icon
    property alias title: titleLabel.text
    property url url
    property bool showFavicon: true

    property alias previewHeight: previewShape.height
    property alias previewWidth: previewShape.width

    signal setCurrent()
    signal removed()

    onPressAndHold: previewShape.openContextMenu()

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: units.gu(1)

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: titleLabel.height

            Loader {
                id: favicon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: Favicon {
                    source: preview.icon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                active: preview.showFavicon
            }

            Label {
                id: titleLabel
                anchors.left: favicon.right
                anchors.leftMargin: showFavicon ? units.gu(1) : 0
                anchors.right: parent.right
                anchors.top: parent.top
                text: preview.title
                elide: Text.ElideRight
                fontSize: "small"
            }
        }

        UbuntuShape {
            id: previewShape
            anchors.left: parent.left
            width: units.gu(26)
            height: units.gu(16)

            source: Image {
                id: previewImage
                source: FileOperations.exists(previewShape.previewUrl) ? previewShape.previewUrl : ""
                sourceSize.width: previewShape.width
                cache: false
            }
            sourceFillMode: UbuntuShape.PreserveAspectCrop
            sourceHorizontalAlignment: UbuntuShape.AlignLeft
            sourceVerticalAlignment: UbuntuShape.AlignTop

            property url previewUrl: Qt.resolvedUrl(PreviewManager.previewPathFromUrl(preview.url))

            Connections {
                target: PreviewManager
                onPreviewSaved: {
                    if (pageUrl !== preview.url) return
                    previewImage.source = ""
                    previewImage.source = previewShape.previewUrl
                }
            }

            function openContextMenu() {
                preview.setCurrent()
                PopupUtils.open(contextMenuComponent, previewShape)
            }
        }
    }

    MouseArea {
        anchors.fill: contentColumn
        acceptedButtons: Qt.RightButton
        onClicked: previewShape.openContextMenu()
    }

    Component {
        id: contextMenuComponent
        ActionSelectionPopover {
            objectName: "urlPreviewDelegate.contextMenu"
            grabDismissAreaEvents: true
            actions: ActionList {
                Action {
                    objectName: "delete"
                    text: i18n.tr("Remove")
                    onTriggered: {
                        preview.removed()
                        preview.GridView.view.forceActiveFocus()
                    }
                }
            }
        }
    }
}
