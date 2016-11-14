/*
 * Copyright (C) 2016 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Florian Boucault <florian.boucault@canonical.com>
 */
import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: tabContour
    property color backgroundColor
    property color contourColor

    TabContourHalf {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: parent.width / 2
        backgroundColor: tabContour.backgroundColor
        contourColor: tabContour.contourColor
    }

    TabContourHalf {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: parent.width / 2
        transform: Scale { origin.x: width/4; origin.y: 0; xScale: -1.0}
        
        backgroundColor: tabContour.backgroundColor
        contourColor: tabContour.contourColor
    }
}
