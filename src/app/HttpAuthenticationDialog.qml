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
import Ubuntu.Components.Popups 1.3 as Popups

Popups.Dialog {
    id: dialog
    title: i18n.tr("Authentication required.")
    // TRANSLATORS: %1 refers to the URL of the current website and %2 is a string that the website sends with more information about the authentication challenge (technically called "realm")
    text: request ? i18n.tr('The website at %1 requires authentication. The website says "%2"').arg(request.host).arg(request.realm) : ""

    property QtObject request: null

    Connections {
        target: request
        onCancelled: PopupUtils.close(dialog)
    }

    TextField {
        id: usernameInput
        objectName: "username"
        placeholderText: i18n.tr("Username")
        onAccepted: {
            request.allow(usernameInput.text, passwordInput.text)
            PopupUtils.close(dialog)
        }
    }

    TextField {
        id: passwordInput
        objectName: "password"
        placeholderText: i18n.tr("Password")
        echoMode: TextInput.Password
        onAccepted: {
            request.allow(usernameInput.text, passwordInput.text)
            PopupUtils.close(dialog)
        }
    }

    Button {
        objectName: "allow"
        text: i18n.tr("OK")
        color: UbuntuColors.green
        onClicked: {
            request.allow(usernameInput.text, passwordInput.text)
            PopupUtils.close(dialog)
        }
    }

    Button {
        objectName: "deny"
        text: i18n.tr("Cancel")
        color: UbuntuColors.coolGrey
        onClicked: {
            request.deny()
            PopupUtils.close(dialog)
        }
    }
}
