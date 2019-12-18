/*
 * Copyright 2013-2016 Canonical Ltd.
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

    __closeOnDismissAreaPress: true


    property string rawData : ""
    property var selectData: rawData.length > 0 ? JSON.parse(rawData) :  []
    //property string selectId: selectData.selectId
    //property var selectOptions: selectData.options
    property string selectedOption: "-1"
    
    signal accept(string text)
    signal dismiss()

    onAccept: PopupUtils.close(selectOverlay)
    onDismiss: PopupUtils.close(selectOverlay)


    Repeater {
        model: selectOverlay.selectData
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
                //fontSize: "x-small"
                text: modelData
            }

            onTriggered: accept(index)
        }


    }


    Connections {
        target: __eventGrabber
        onPressed: {
            dismiss()

        }
    }

//    // adjust default dialog visuals to custom requirements
//    Binding {
//        target: background
//        property: "opacity"
//        value: 0.2
//    }




}
