/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 0.1

Dialog {
    id: dialog

    property QtObject permission: null

    title: i18n.tr("Permission Request")

    Button {
        text: i18n.tr("Deny")
        color: UbuntuColors.warmGrey
        onClicked: {
            permission.allow = false
            PopupUtils.close(dialog)
        }
    }

    Button {
        text: i18n.tr("Allow")
        color: UbuntuColors.orange
        onClicked: {
            permission.allow = true
            PopupUtils.close(dialog)
        }
    }
}
