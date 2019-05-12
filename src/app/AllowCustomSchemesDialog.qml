/*
 * Copyright 2019 ubports
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

ModalDialog {
    objectName: "confirmDialog"
    title: i18n.tr("Custom URL schemes")

    property string url
    property string domain
    property bool showAllowPermanentlyCheckBox

    message: i18n.tr("The following url with a custom scheme was blocked:") + "\n" +
                                           url + "\n\n" +
                                           i18n.tr("Should all custom URL schemes from domain %1 be allowed?".arg(domain));

    signal allow()
    signal allowPermanently()
    signal cancel()
    
    onAllow: hide()
    onAllowPermanently: hide()
    onCancel: hide()

    ListItemLayout {
        visible: showAllowPermanentlyCheckBox
        title.text: i18n.tr("Save permanently")
        CheckBox {
            id: allowPermanentlyCheckBox
         }
    }
    Button {
        text: i18n.tr("OK")
        color: theme.palette.normal.positive
        objectName: "okButton"
        onClicked: allowPermanentlyCheckBox.checked ? allowPermanently() : allow()
    }
    Button {
        objectName: "cancelButton"
        text: i18n.tr("Cancel")
        enabled: ! allowPermanentlyCheckBox.checked
        onClicked: cancel()
    }
}
