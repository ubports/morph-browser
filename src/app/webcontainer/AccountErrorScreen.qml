/*
 * Copyright 2015 Canonical Ltd.
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

Rectangle {
    id: root

    property alias message: messageLabel.text
    signal closed()

    anchors.fill: parent

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(4)

        spacing: units.gu(3)

        Label {
            width: parent.width
            fontSize: "x-large"
            text: i18n.tr("Account error")
        }

        Label {
            id: messageLabel
            width: parent.width
            wrapMode: Text.Wrap
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            text: i18n.tr("Close")
            onClicked: root.closed()
        }
    }
}
