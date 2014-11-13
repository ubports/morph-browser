/*
 * Copyright 2014 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.0
import Ubuntu.Components.Popups 1.0
import com.canonical.Oxide 1.0 as Oxide

Popover {
    id: certificatePopover

    property var securityStatus

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
            visible: securityStatus.securityLevel == Oxide.SecurityStatus.SecurityLevelWarning
            spacing: units.gu(0.5)

            Row {
                width: parent.width
                spacing: units.gu(0.5)

                Icon {
                    name: "security-alert"
                    height: units.gu(2)
                    width: height
                }

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: i18n.tr("This site has insecure content")
                    fontSize: "x-small"
                }
            }

            ThinDivider {
                width: parent.width
                anchors.leftMargin: 0
                anchors.rightMargin: 0
            }
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: i18n.tr("You are connected to")
            fontSize: "x-small"
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: securityStatus.certificate.subjectDisplayName
            fontSize: "x-small"
        }

        ThinDivider {
            width: parent.width
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            visible: orgName.visible || localityName.visible || stateName.visible || countryName.visible
        }

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            visible: orgName.visible
            text: i18n.tr("Which is run by")
            fontSize: "x-small"
        }

        Label {
            id: orgName
            width: parent.width
            wrapMode: Text.WordWrap
            visible: text.length > 0
            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrOrganizationName).join(", ")
            fontSize: "x-small"
        }

        Label {
            id: localityName
            width: parent.width
            wrapMode: Text.WordWrap
            visible: text.length > 0
            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrLocalityName).join(", ")
            fontSize: "x-small"
        }

        Label {
            id: stateName
            width: parent.width
            wrapMode: Text.WordWrap
            visible: text.length > 0
            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrStateOrProvinceName).join(", ")
            fontSize: "x-small"
        }

        Label {
            id: countryName
            width: parent.width
            wrapMode: Text.WordWrap
            visible: text.length > 0
            text: securityStatus.certificate.getSubjectInfo(Oxide.SslCertificate.PrincipalAttrCountryName).join(", ")
            fontSize: "x-small"
        }

        Item {
            height: units.gu(1.5)
            width: parent.width
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: PopupUtils.close(certificatePopover)
    }
}
