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
import Ubuntu.Components.ListItems 1.0

Dialog {
    title: i18n.tr("Bookmark Added")

    property alias bookmarkTitle: titleTextField.text
    property alias folderModel: folderOptionSelector.model

    readonly property string selectedFolder: newFolderTextField.text ?
                                                newFolderTextField.text :
                                                folderModel.get(folderOptionSelector.selectedIndex).folder

    signal okButtonClicked()

    Label {
        text: i18n.tr("Name")
    }

    TextField {
        id: titleTextField
    }

    OptionSelector {
        id: folderOptionSelector
        opacity: newFolderTextField.text ? 0.0 : 1.0 
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0.0

        text: i18n.tr("Save in")
        delegate: selectorDelegate
    }

    Component {
        id: selectorDelegate
        OptionSelectorDelegate { text: folder === "" ? i18n.tr("All Bookmarks") : folder }
    }

    Label {
        opacity: newFolderTextField.text ? 1.0 : 0.0 
        Behavior on opacity { UbuntuNumberAnimation {} }
        visible: opacity > 0.0

        text: i18n.tr("Save in")
    }

    TextField {
        id: newFolderTextField
        placeholderText: i18n.tr("New Folder")
    }

    Button {
        anchors { left: parent.left; right: parent.right }
        text: i18n.tr("Ok")
        color: UbuntuColors.green
        onClicked: okButtonClicked()
    }
}
