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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import webbrowserapp.private 0.1

Popover {
    id: bookmarkOptions

    property url bookmarkUrl
    property alias bookmarkTitle: titleTextField.text

    readonly property string bookmarkFolder: folderOptionSelector.model.get(folderOptionSelector.selectedIndex).folder

    contentHeight: bookmarkOptionsColumn.childrenRect.height + units.gu(2)

    onVisibleChanged: {
        if (!visible) {
            BookmarksModel.remove(bookmarkUrl)
        }
    }

    Component.onDestruction: {
        if (BookmarksModel.contains(bookmarkUrl)) {
            BookmarksModel.update(bookmarkUrl, bookmarkTitle, bookmarkFolder)
        }
    }

    // Fragile workaround for https://launchpad.net/bugs/1546677.
    // By destroying the popover, its visibility isn’t changed to
    // false, and thus the bookmark is not removed.
    Keys.onEnterPressed: bookmarkOptions.destroy()
    Keys.onReturnPressed: bookmarkOptions.destroy()

    Column {
        id: bookmarkOptionsColumn

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: units.gu(1)
        }

        spacing: units.gu(1)

        Label {
            font.bold: true
            text: i18n.tr("Bookmark Added")
        }

        Label {
            // TRANSLATORS: Field where the title of bookmarked URL can be changed
            text: i18n.tr("Name")
            fontSize: "small"
        }

        TextField {
            id: titleTextField
            objectName: "titleTextField"

            anchors {
                left: parent.left
                right: parent.right
            }

            inputMethodHints: Qt.ImhNoPredictiveText
        }

        Label {
            // TRANSLATORS: Field to choose the folder where bookmarked URL will be saved in
            text: i18n.tr("Save in")
            fontSize: "small"
        }

        OptionSelector {
            id: folderOptionSelector

            delegate: OptionSelectorDelegate { text: folder === "" ? i18n.tr("All Bookmarks") : folder }
            containerHeight: itemHeight * 3
            model: BookmarksFolderListModel {
                sourceModel: BookmarksModel
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: newFolderButton.height

            Button {
                id: newFolderButton
                objectName: "bookmarkOptions.newButton"
                text: i18n.tr("New Folder")
                onClicked: PopupUtils.open(newFolderDialog)
            }

            Button {
                id: okButton
                objectName: "bookmarkOptions.okButton"
                anchors.right: parent.right
                text: i18n.tr("OK")
                color: theme.palette.normal.positive
                onClicked: bookmarkOptions.destroy()
            }
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
                Qt.inputMethod.hide()
                folderOptionSelector.model.createNewFolder(folder)
                folderOptionSelector.selectedIndex = folderOptionSelector.model.indexOf(folder)
                folderOptionSelector.currentlyExpanded = false
                PopupUtils.close(dialogue)
            }

            TextField {
                id: folderTextField
                objectName: "newFolderDialog.text"
                inputMethodHints: Qt.ImhNoPredictiveText
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
                color: theme.palette.normal.positive
                // Button took focus on press what makes the keyboard be
                // dismissed and that could make the Button moves between the
                // press and the release. Button onClicked is not triggered
                // if the release event happens outside of the button.
                // See: http://pad.lv/1415023
                activeFocusOnPress: false
                onClicked: createNewFolder(folderTextField.text)
            }
        }
    }
}
