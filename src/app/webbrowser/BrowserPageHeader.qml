 /*
 * Copyright 2015-2016 Canonical Ltd.
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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

/*
 * Component to use as page header in settings page, download page and 
 * subpages
 *
 * It has a back() signal fired when back button is pressed, a text
 * property to set the page title and an actions property which
 * displays action icons on the right of header.
 */

Item {
    id: root
    signal back()
    property string text
    property alias actions: actionBar.actions
    property alias color: title.color

    height: title.height + divider.height

    anchors {
        left: parent.left
        right: parent.right
    }

    MouseArea {
        // Prevent click events from propagating through to the view below
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Rectangle {
        id: title

        height: units.gu(6) - divider.height
        anchors { left: parent.left; right: parent.right }
        color: "#f6f6f6"

        AbstractButton {
            id: backButton
            objectName: "backButton"

            width: height

            activeFocusOnPress: false
            onTriggered: root.back()
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                color: "#E6E6E6"
                visible: parent.pressed
            }

            Icon {
                name: "back"
                anchors {
                    fill: parent
                    topMargin: units.gu(2)
                    bottomMargin: units.gu(2)
                }
            }
        }

        Label {
            anchors {
                left: backButton.right
                verticalCenter: parent.verticalCenter
            }
            text: root.text
            fontSize: 'x-large'
        }

        ActionBar {
            id: actionBar
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }

        
    }

    Rectangle {
        id: divider
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.dp(1)
        color: Qt.darker(title.color, 1.1)
    }
}
