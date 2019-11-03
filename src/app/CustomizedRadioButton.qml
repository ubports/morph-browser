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

import QtQuick 2.6
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3

RadioButton {
    property string color
    id: control
    checked: false

    indicator: Rectangle {
        implicitWidth: units.gu(3)
        implicitHeight: units.gu(3)
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13
        border.color: theme.palette.selected.base
        antialiasing: true

        Rectangle {
            anchors.centerIn: parent
            width: units.gu(2)
            height: units.gu(2)
            radius: units.gu(1)
            color: theme.palette.selected.base
            visible: control.checked
            antialiasing: true
        }
    }

    contentItem: Text {
        id: contentText
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.color
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
