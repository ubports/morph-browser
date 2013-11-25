/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1 as Popups
import Ubuntu.Content 0.1

Popups.Dialog {
    id: picker
    title: i18n.tr("Pick content to upload")
    property var activeTransfer

    UbuntuShape {
        height: width
        image: Image {
            id: preview
            fillMode: Image.PreserveAspectCrop
        }

        MouseArea {
            anchors.fill: parent
            onClicked: startContentPicking()
        }

        ContentImportHint {
            anchors.fill: parent
            activeTransfer: picker.activeTransfer
        }
    }

    Button {
        text: i18n.tr("OK")
        color: "green"
        enabled: preview.source
        onClicked: model.accept(String(preview.source).replace("file://", ""))
    }

    Button {
        text: i18n.tr("Cancel")
        color: UbuntuColors.coolGrey
        onClicked: model.reject()
    }

    function startContentPicking() {
        activeTransfer = ContentHub.importContent(ContentType.Pictures);
        activeTransfer.selectionType = ContentTransfer.Single;
        activeTransfer.start();
    }

    Component.onCompleted: {
        show();
        startContentPicking();
    }

    Connections {
        target: picker.activeTransfer
        onStateChanged: {
            if (picker.activeTransfer.state === ContentTransfer.Charged) {
                var importItem = picker.activeTransfer.items[0];
                preview.source = importItem.url
            }
        }
    }
}
