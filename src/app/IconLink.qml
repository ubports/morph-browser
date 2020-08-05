/*
 * Copyright 2020 UBports
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
import Ubuntu.Components 1.3

Item {
    id: iconLink
    property string name
    signal clicked()

    Icon {
         id: icon
         anchors.fill: parent
         name: iconLink.name

         height: units.gu(2)
         width: height

         MouseArea {
            anchors.fill: parent
            onClicked: iconLink.clicked()
         }
   }
}
