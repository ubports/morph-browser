/*
 * Copyright 2020 UBports Foundation
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
import Ubuntu.Components.Popups 1.3

Dialog {
    id: dialog
    
    property string securityOrigin
    property bool showRememberDecisionCheckBox
    modal: true

    title: i18n.tr("Permission Request")
    text: securityOrigin + "<br>" + i18n.tr("This page wants to create notifications.")
    
    signal allow()
    signal allowPermanently()
    signal reject()
    signal rejectPermanently()
    
    onAllow: { PopupUtils.close(dialog); }
    onAllowPermanently: { PopupUtils.close(dialog); }
    onReject: { PopupUtils.close(dialog); }
    onRejectPermanently: { PopupUtils.close(dialog); }

    ListItemLayout {
        visible: showRememberDecisionCheckBox
        title.text: i18n.tr("Remember decision")
        CheckBox {
            id: rememberDecisionCheckBox
         }
    }
    Button {
        objectName: "allow"
        text: i18n.tr("Allow")
        color: theme.palette.normal.positive
        onClicked: rememberDecisionCheckBox.checked ? allowPermanently() : allow()
    }
    Button {
        objectName: "deny"
        text: i18n.tr("Deny")
        onClicked: rememberDecisionCheckBox.checked ? rejectPermanently() : reject()
    }
}
