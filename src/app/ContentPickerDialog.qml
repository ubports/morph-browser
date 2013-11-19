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
    title: i18n.tr("Content Picker")
    property var activeTransfer

    Image {
        id: preview
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(10)
    }

    Button {
        text: i18n.tr("OK")
        color: "green"
        onClicked: model.accept(preview.source)
    }

    Button {
        text: i18n.tr("Cancel")
        color: UbuntuColors.coolGrey
        onClicked: model.reject()
    }

    Component.onCompleted: {
        console.log(">>>>>>> INSTANTIATED")
        show()
        activeTransfer = ContentHub.importContent(ContentType.Pictures);
        activeTransfer.selectionType = ContentTransfer.Multiple;
        activeTransfer.start();
    }

    Connections {
        target: picker.activeTransfer
        onStateChanged: {
            if (picker.activeTransfer.state === ContentTransfer.Charged) {
                var importItmes = picker.activeTransfer.items;
                console.log(importItems);
            }
        }
    }
}
