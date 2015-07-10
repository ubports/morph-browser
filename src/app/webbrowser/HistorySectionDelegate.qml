/*
 * Copyright 2014-2015 Canonical Ltd.
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

import QtQuick 2.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

Item {
    height: units.gu(5.5)

    Label {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: units.gu(1.5)
        }
        height: units.gu(2)

        text: {
            var today = new Date()
            var yesterday = new Date()
            yesterday.setDate(yesterday.getDate() - 1)
            var sectionDate = new Date(section)
            if ((sectionDate.getUTCFullYear() == today.getFullYear()) &&
                (sectionDate.getUTCMonth() == today.getMonth())) {
                var dayDifference = sectionDate.getUTCDate() - today.getDate()
                if (dayDifference == 0) {
                    return i18n.tr("Last Visited")
                } else if (dayDifference == -1) {
                    return i18n.tr("Yesterday")
                }
            }
            return Qt.formatDate(section, Qt.DefaultLocaleLongDate)
        }

        fontSize: "small"
        color: UbuntuColors.darkGrey
    }

    ListItem.ThinDivider {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: units.gu(1)
        }
    }
}
