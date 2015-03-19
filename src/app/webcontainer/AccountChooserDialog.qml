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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1

Dialog {
    id: root

    property string providerId: ""
    property string applicationId: ""
    property bool accountMandatory: true
    property var accountsModel: null

    signal accountSelected(int accountId)
    signal cancel()

    property var __selectedAccount: settings.selectedAccount

    Settings {
        id: settings
        property int selectedAccount
    }

    Setup {
        id: setup
        applicationId: root.applicationId
        providerId: root.providerId
        onFinished: {
            if ("accountId" in reply) {
                root.chooseAccount(reply.accountId)
            } else {
                root.cancel()
            }
        }
    }

    Repeater {
        model: accountsModel
        AccountItem {
            providerName: model.providerName
            accountName: model.displayName
            selected: model.accountId === root.__selectedAccount
            onClicked: root.__selectedAccount = model.accountId
        }
    }

    ListItem.Standard {
        id: addAccountButton
        text: i18n.tr("Add account")
        iconName: "add"
        selected: root.__selectedAccount === -1
        onClicked: root.__selectedAccount = -1
    }

    ListItem.Standard {
        id: skipButton
        visible: !root.accountMandatory
        text: i18n.tr("Don't use an account")
        selected: root.__selectedAccount === -2
        onClicked: root.__selectedAccount = -2
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        height: childrenRect.height + units.gu(1)

        Button {
            id: cancelButton
            anchors.left: parent.left
            width: parent.width / 2 - units.gu(1)
            text: i18n.tr("Cancel")
            onClicked: root.cancel()
        }

        Button {
            anchors.right: parent.right
            width: cancelButton.width
            text: i18n.tr("OK")
            onClicked: root.onConfirmed()
        }
    }

    function chooseAccount(accountId) {
        for (var i = 0; i < accountsModel.count; i++) {
            if (accountsModel.get(i, "accountId") === accountId) {
                settings.selectedAccount = accountId
                root.accountSelected(accountId)
                return
            }
        }

        // The selected account was not found
        settings.selectedAccount = -1
        root.cancel()
    }

    function onConfirmed() {
        if (__selectedAccount === -2) {
            root.selectedAccount(0)
        } else if (__selectedAccount === -1) {
            setup.exec()
        } else {
            chooseAccount(__selectedAccount)
        }
    }
}
