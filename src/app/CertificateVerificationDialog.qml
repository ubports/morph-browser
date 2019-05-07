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
import Ubuntu.Components.Popups 1.3 as Popups

Popups.Dialog {
    title: i18n.tr("This connection is untrusted")
    // TRANSLATORS: %1 refers to the hostname
    text: i18n.tr("You are trying to securely reach %1, but the security certificate of this website is not trusted. Reason: %2").arg(host).arg(localizedErrorMessage)

    property string host
    property string localizedErrorMessage
    property bool errorIsOverridable

    signal accept()
    signal reject()

    onAccept: hide()
    onReject: hide()

    Button {
        text: i18n.tr("Proceed anyway")
        visible: errorIsOverridable
        color: theme.palette.normal.negative
        onClicked: accept()
    }

    Button {
        text: i18n.tr("Cancel")
        onClicked: reject()
    }

    Component.onCompleted: show()
}
