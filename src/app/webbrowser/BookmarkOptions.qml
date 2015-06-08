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
import Ubuntu.Components.Popups 1.0

Popover {
    id: bookmarkOptions

    property alias bookmarkTitle: titleTextField.text
    property alias folderModel: folderOptionSelector.model

    readonly property string bookmarkFolder: folderModel.get(folderOptionSelector.selectedIndex).folder

    Column {
        id: bookmarkOptionsColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: units.gu(3)
            rightMargin: units.gu(3)
        }

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

        Button {
            text: i18n.tr("New Folder")
            onClicked: PopupUtils.open(newFolderDialog)
        }
    }

    Component {
        id: newFolderDialog

        Dialog {
            id: dialogue
            objectName: "newFolderDialog"

            title: i18n.tr("Create new folder")

            Component.onCompleted: {
                folderTextField.forceActiveFocus()
            }

            function createNewFolder(folder) {
                folderModel.createNewFolder(folder)
                folderOptionSelector.selectedIndex = folderModel.getIndex(folder) 
                PopupUtils.close(dialogue)
            }

            TextField {
                id: folderTextField
                objectName: "newFolderDialog.text"
                placeholderText: i18n.tr("New Folder")
                onAccepted: createNewFolder(text)
            }

            Button {
                objectName: "newFolderDialog.cancelButton"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }

            Button {
                objectName: "newFolderDialog.saveButton"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Save")
                enabled: folderTextField.text
                color: "#3fb24f"
                onClicked: createNewFolder(folderTextField.text)
            }
        }
    }
}
