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
 *              Andrew Hayzen <andrew.hayzen@canonical.com>
 */

import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: tabIcon

    property string iconName
    property alias iconSource: image.source
    property alias fallbackIcon: fallbackIcon.name

    implicitHeight: units.gu(2)
    implicitWidth: units.gu(2)

    Component.onCompleted: image.completed = true

    Image {
        id: image
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: completed && tabIcon.iconName ? "image://theme/%1".arg(tabIcon.name) : ""
        sourceSize {
            height: tabIcon.height
            width: tabIcon.width
        }

        property bool completed: false
    }

    Icon {
        id: fallbackIcon
        anchors.fill: parent
        asynchronous: true
        visible: (image.status !== Image.Ready) || !image.source.toString()
    }
}