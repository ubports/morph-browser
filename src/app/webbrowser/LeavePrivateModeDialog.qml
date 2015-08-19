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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Dialog {
    title: i18n.tr("Going to public mode will close all private tabs")

    signal cancelButtonClicked()
    signal okButtonClicked()

    Button {
        objectName: "leavePrivateModeDialog.cancelButton"
        anchors { left: parent.left; right: parent.right }
        text: i18n.tr("Cancel")
        onClicked: cancelButtonClicked()
    }

    Button {
        objectName: "leavePrivateModeDialog.okButton"
        anchors { left: parent.left; right: parent.right }
        text: i18n.tr("OK")
        color: UbuntuColors.green
        onClicked: okButtonClicked()
    }
}
