/*
 * Copyright 2014-2016 Canonical Ltd.
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
    objectName: "beforeUnloadDialog"
    title: i18n.tr("Confirm Navigation")
    
    signal accept()
    signal reject()
    
    onAccept: hide()
    onReject: hide()

    Button {
        text: i18n.tr("Leave")
        color: theme.palette.normal.negative
        objectName: "leaveButton"
        onClicked: accept()
    }

    Button {
        objectName: "stayButton"
        text: i18n.tr("Stay")
        onClicked: reject()
    }
}
