/*
 * Copyright 2019 Chris Clime
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
import webbrowsercommon.private 0.1

ModalDialog {
    objectName: "allowOrBlockDomain"
    title: i18n.tr("Block domain")

    property string domain

    message: i18n.tr("About to access domain %1. Do you want to block this domain from now on?".arg(domain));

    signal allow()
    signal block()
    signal cancel()
    
    onAllow: hide()
    onBlock: hide()
    onCancel: hide()

    Button {
        text: i18n.tr("Block domain")
        color: theme.palette.normal.negative
        objectName: "blockButton"
        onClicked: block()
    }
    Button {
        text: i18n.tr("Allow domain")
        objectName: "allowButton"
        onClicked: allow()
    }
    Button {
        objectName: "cancelButton"
        text: i18n.tr("Cancel")
        onClicked: cancel()
    }

    Connections {
        target: DomainPermissionsModel
        onDataChanged: {
            if (DomainPermissionsModel.getPermission(domain) !== DomainPermissionsModel.NotSet) {
                cancel();
            }
        }
    }
}
