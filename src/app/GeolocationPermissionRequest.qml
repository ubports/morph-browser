/*
 * Copyright 2014-2016 Canonical Ltd.
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
    id: dialog

    //property QtObject request: null
    property url origin
    property int feature

    title: i18n.tr("Permission Request")
    text: origin + "<br>" + i18n.tr("This page wants to know your device’s location.")
    
    signal accept()
    signal reject()
    
    onAccept: { PopupUtils.close(dialog); grantFeaturePermission(origin, feature, true); }
    onReject: { PopupUtils.close(dialog); grantFeaturePermission(origin, feature, false); }

    Button {
        objectName: "deny"
        text: i18n.tr("Deny")
        onClicked: reject()
    }

    Button {
        objectName: "allow"
        text: i18n.tr("Allow")
        color: theme.palette.normal.positive
        onClicked: accept()
    }
}
