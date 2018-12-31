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

Item {
    id: newPrivateTabView
    objectName: "newPrivateTabView"

    Icon {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: titleLabel.top
        }

        width: units.gu(10)
        height: width

        name: "private-browsing"
    }    

    Label {
        id: titleLabel
        anchors.centerIn: parent
        text: i18n.tr("This is a private tab")
        color: theme.palette.selected.base
        fontSize: "medium"
    }

    Label {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: titleLabel.bottom
            topMargin: units.gu(5)
        }

        width: units.gu(25)
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("Pages that you view in this tab won't appear in your browser history.\nBookmarks you create will be preserved, however.")
        color: theme.palette.selected.base
        fontSize: "x-small"
    }
}
