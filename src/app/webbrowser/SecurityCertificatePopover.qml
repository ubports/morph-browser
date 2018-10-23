/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3
import Ubuntu.Components.Popups 1.3
import Morph.Web 0.1

Popover {
    id: certificatePopover

    property var certificateError: null
    property string host

    property bool isWarning: false
    readonly property bool isError:  (certificateError !== null)

    Column {
        width: parent.width - units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: units.gu(0.5)

        Item {
            height: units.gu(1.5)
            width: parent.width
        }

        Column {
            width: parent.width
            visible: certificatePopover.isWarning || certificatePopover.isError
            spacing: units.gu(0.5)

            Row {
                width: parent.width
                spacing: units.gu(0.5)

                Icon {
                    id: alertIcon
                    name: "security-alert"
                    height: units.gu(2)
                    width: height
                }

                Column {
                    width: parent.width - alertIcon.width - parent.spacing
                    height: childrenRect.height
                    spacing: units.gu(0.5)

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        fontSize: "x-small"
                        text: certificatePopover.isWarning ?
                                  i18n.tr("This site has insecure content") :
                                  i18n.tr("Identity Not Verified")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        visible: certificatePopover.isError
                        fontSize: "x-small"
                        text: i18n.tr("The identity of this website has not been verified.")
                    }

                    Label {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        visible: certificatePopover.isError
                        fontSize: "x-small"
                        text: certificatePopover.certificateError ? certificatePopover.certificateError.description : ""
                   }

                }
            }

            ThinDivider {
                width: parent.width
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                visible: !certificatePopover.isError
            }
        }

        Column {
            width: parent.width
            spacing: units.gu(0.5)
            visible: !certificatePopover.isError

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: i18n.tr("You are connected to %1 via HTTPS. The certificate is valid.".arg(host))
                fontSize: "x-small"
            }
        }

        Item {
            height: units.gu(1)
            width: parent.width
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: PopupUtils.close(certificatePopover)
    }
}
