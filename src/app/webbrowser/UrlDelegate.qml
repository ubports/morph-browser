/*
 * Copyright 2014-2017 Canonical Ltd.
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
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import ".."

ListItem {
    id: urlDelegate

    property alias icon: icon.source
    property alias title: title.text
    property alias url: url.text

    property alias headerComponent: headerComponentLoader.sourceComponent

    property bool removable: true

    divider.visible: false

    signal removed()

    RowLayout {
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: units.gu(1.5)
            right: parent.right
            rightMargin: units.gu(1.5)
        }
        spacing: units.gu(1)

        Loader {
            id: headerComponentLoader
            anchors.verticalCenter: parent.verticalCenter
            visible: status == Loader.Ready
        }

        Favicon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            Layout.fillWidth: true
            anchors.verticalCenter: parent.verticalCenter

            Label {
                id: title
                anchors {
                    left: parent.left
                    right: parent.right
                }
                textSize: Label.Small
                color: theme.palette.normal.backgroundSecondaryText
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Label {
                id: url
                anchors {
                    left: parent.left
                    right: parent.right
                }
                textSize: Label.XSmall
                color: theme.palette.normal.backgroundTertiaryText
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    ListItemActions {
        id: listItemActions
        actions: [
            Action {
                objectName: "leadingAction.delete"
                iconName: "delete"
                onTriggered: urlDelegate.removed()
            }
        ]
    }

    leadingActions: removable ? listItemActions : null
}
