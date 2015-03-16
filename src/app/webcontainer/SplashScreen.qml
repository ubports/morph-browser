/*
 * Copyright 2013-2014 Canonical Ltd.
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
import Ubuntu.OnlineAccounts 0.1

Column {
    id: root

    property string providerName
    property string applicationName
    property alias iconSource: icon.source
    property bool accountMandatory: true

    signal chooseAccount()
    signal skip()

    anchors.fill: parent
    spacing: units.gu(2)

    Icon {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        width: units.gu(10)
        height: width
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        fontSize: "x-large"
        text: root.applicationName
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: i18n.tr("<b>%1</b> needs to access your %1 online account.").arg(root.applicationName).arg(root.providerName)
        visible: root.accountMandatory
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: i18n.tr("<b>%1</b> would like to access your %1 online account.").arg(root.applicationName).arg(root.providerName)
        visible: !root.accountMandatory
    }

    Label {
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: i18n.tr("Choose an account now, or skip this step and choose an online account later.")
        visible: !root.accountMandatory
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        height: units.gu(6)

        Button {
            anchors.left: parent.left
            width: parent.width / 2 - units.gu(1)
            text: root.accountMandatory ? i18n.tr("Close the app") : i18n.tr("Skip")
            onClicked: root.accountMandatory ? Qt.quit() : root.skip()
        }

        Button {
            anchors.right: parent.right
            width: parent.width / 2 - units.gu(1)
            text: i18n.tr("Choose account")
            onClicked: root.chooseAccount()
        }
    }
}
