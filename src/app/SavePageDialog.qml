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
    title: i18n.tr(canSaveAsHtml && canSaveAsPdf ? "Save page as HTML / PDF" : "Save page")
    
    property bool canSaveAsHtml: false
    property bool canDownload: false
    property bool canSaveAsPdf: false

    signal saveAsHtml()
    signal download()
    signal saveAsPdf()
    signal cancel()
    
    onSaveAsHtml: hide()
    onDownload: hide()
    onSaveAsPdf: hide()
    onCancel: hide()

    Button {
        text: i18n.tr("Save as HTML")
        color: theme.palette.normal.foreground
        objectName: "savehtml"
        onClicked: saveAsHtml()
        visible: canSaveAsHtml
    }

    Button {
        text: i18n.tr("Download")
        color: theme.palette.normal.foreground
        objectName: "download"
        onClicked: download()
        visible: canDownload
    }

    // ToDo: add page size and orientation for the PDF

    Button {
        text: i18n.tr("Save as PDF")
        color: theme.palette.normal.foreground
        objectName: "savepdf"
        onClicked: saveAsPdf()
        visible: canSaveAsPdf
    }

    Button {
        objectName: "cancelButton"
        text: i18n.tr("Cancel")
        onClicked: cancel()
    }
}
