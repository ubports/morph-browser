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
import Ubuntu.Components.Popups 1.3 as Popups

Popups.Dialog {
    id: dialog
    title: i18n.tr("Authentication required.")
    // TRANSLATORS: %1 refers to the URL of the current website and %2 is a string that the website sends with more information about the authentication challenge (technically called "realm")
    text: (host && realm) ? i18n.tr("The website at %1 requires authentication. The website says \"%2\"").arg(this.host).arg(this.realm) : ""

    //property QtObject request: null
    
    property string host
    property string realm
    
    signal accept(string username, string password)
    signal reject()
    
    onAccept: PopupUtils.close(dialog)
    onReject: PopupUtils.close(dialog)

    /*
    Connections {
        target: request
        onCancelled: PopupUtils.close(dialog)
    }
    */

    TextField {
        id: usernameInput
        objectName: "username"
        placeholderText: i18n.tr("Username")
        onAccepted: {
            Qt.inputMethod.commit()
            accept(usernameInput.text, passwordInput.text)
        }
    }

    TextField {
        id: passwordInput
        objectName: "password"
        placeholderText: i18n.tr("Password")
        echoMode: TextInput.Password
        onAccepted: {
            Qt.inputMethod.commit()
            accept(usernameInput.text, passwordInput.text)
        }
    }

    Button {
        objectName: "allow"
        text: i18n.tr("OK")
        color: theme.palette.normal.positive
        onClicked: {
            Qt.inputMethod.commit()
            accept(usernameInput.text, passwordInput.text)
        }
    }

    Button {
        objectName: "deny"
        text: i18n.tr("Cancel")
        onClicked: reject()
    }
}
