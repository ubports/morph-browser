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

import QtQuick 2.0
import Ubuntu.Components 1.1

Rectangle {
    id: bookmarkOptions

    property alias bookmarkTitle: titleTextField.text
    property alias folderModel: folderOptionSelector.model

    readonly property string bookmarkFolder: {
        if (state == "exisitngFolder") {
            return folderModel.get(folderOptionSelector.selectedIndex).folder
        } else if (state == "newFolder") {
            return newFolderTextField.text
        }
    }

    signal dismiss()

    height: bookmarkOptionsColumn.height + units.gu(4)
    border.color: UbuntuColors.darkGrey

    state: "existingFolder"
    states: [
        State {
            name: "newFolder"
            PropertyChanges { target: folderOptionSelector; visible: false}
            PropertyChanges { target: newFolderTextField; visible: true}
            PropertyChanges { target: changeFolderStateButton; text: i18n.tr("Choose Folder")}
        },
        State {
            name: "existingFolder"
            PropertyChanges { target: folderOptionSelector; visible: true}
            PropertyChanges { target: newFolderTextField; visible: false}
            PropertyChanges { target: changeFolderStateButton; text: i18n.tr("New Folder")}
        }
    ]

    InverseMouseArea {
        anchors.fill: parent
        onPressed: {
            bookmarkOptions.dismiss()
            mouse.accepted = false
        }
    }

    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: bookmarkOptionsColumn

        anchors.centerIn: parent
        width: parent.width - units.gu(2)
        spacing: units.gu(2)

        Label {
            font.bold: true
            text: i18n.tr("Bookmark Added")
        }

        Label {
            text: i18n.tr("Name")
        }

        TextField {
            id: titleTextField

            width: parent.width
        }

        OptionSelector {
            id: folderOptionSelector

            text: i18n.tr("Save in")
            delegate: selectorDelegate
        }

        Component {
            id: selectorDelegate
            OptionSelectorDelegate { text: folder === "" ? i18n.tr("All Bookmarks") : folder }
        }

        Label {
            id: newFolderLabel

            visible: newFolderTextField.visible
            text: i18n.tr("Save in")
        }

        TextField {
            id: newFolderTextField

            width: parent.width
            placeholderText: i18n.tr("New Folder")

            onVisibleChanged: {
                if (visible) {
                    forceActiveFocus()
                }
            }
        }

        Button {
            id: changeFolderStateButton
            onClicked: {
                if (bookmarkOptions.state == "existingFolder") {
                    bookmarkOptions.state = "newFolder"
                } else if (bookmarkOptions.state == "newFolder") {
                    bookmarkOptions.state = "existingFolder"
                }
            }
        }
    }
}
