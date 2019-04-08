/*
 * Copyright 2013-2016 Canonical Ltd.
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
    objectName: "savePageDialog"
    title: i18n.tr("Save page as HTML / PDF")
    
    signal saveAsHtml()
    signal saveAsPdf()
    signal cancel()
    
    onSaveAsHtml: hide()
    onSaveAsPdf: hide()
    onCancel: hide()

    Button {
        text: i18n.tr("Save as HTML")
        color: theme.palette.normal.foreground
        objectName: "savehtml"
        onClicked: saveAsHtml()
    }

    // ToDo: add page size and orientation for the PDF

    Button {
        text: i18n.tr("Save as PDF")
        color: theme.palette.normal.foreground
        objectName: "savepdf"
        onClicked: saveAsPdf()
    }

    Button {
        objectName: "cancelButton"
        text: i18n.tr("Cancel")
        onClicked: cancel()
    }
}
