/*
 * Copyright 2014-2016 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItem

Item {
    height: units.gu(5.5)

    property string todaySectionTitle: i18n.tr("Last Visited") 

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
                    return todaySectionTitle
                } else if (dayDifference == -1) {
                    return i18n.tr("Yesterday")
                }
            }
            return Qt.formatDate(section, Qt.DefaultLocaleLongDate)
        }

        fontSize: "small"
        color: theme.palette.normal.backgroundSecondaryText
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
