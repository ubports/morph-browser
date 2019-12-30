/*
 * Copyright 2016-2020 Ubports.
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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3 as Popups

Popups.Dialog {
    id: selectOverlay
    objectName: "selectOverrideDialog"
    modal: true

    __dimBackground: false //avoid default opaque background
    grabDismissAreaEvents: false //allow this component to handle the click on the background

    property string options: ""
    property var selectOptions: options.length > 0 ? JSON.parse(options) :  []
    
    signal accept(string text)
    signal reject()

    onAccept: hide()
    onReject: hide()


    Repeater {
        model: selectOverlay.selectOptions
        delegate: ListItems.Empty {
            showDivider: true

            height: units.gu(5)

            Label {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                text: modelData
            }

            onTriggered: accept(index)
        }


    }

    //make sure reject is fired when closing the popup
    Connections {
        target: __eventGrabber
        onPressed: {
            reject()

        }
    }


}
