/*
 * Copyright 2013-2015 Canonical Ltd.
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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1

SplashScreen {
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

    Column {
        anchors { left: parent.left; right: parent.right }
        spacing: units.gu(1)

        ListItem.Caption {
            text: i18n.tr("No accounts have been linked to this webapp; press the item below to add an account.")
            visible: accountsModel.count === 0
        }

        Repeater {
            model: accountsModel
            AccountItem {
                providerName: model.providerName
                accountName: model.displayName
                selected: model.accountId === root.__selectedAccount
                onClicked: root.onConfirmed(model.accountId)
            }
        }

        ListItem.Standard {
            id: addAccountButton
            text: i18n.tr("Add account")
            iconName: "add"
            selected: root.__selectedAccount === -1
            onClicked: root.onConfirmed(-1)
        }

        ListItem.Standard {
            id: skipButton
            visible: !root.accountMandatory
            text: i18n.tr("Don't use an account")
            selected: root.__selectedAccount === -2
            onClicked: root.onConfirmed(-2)
        }

        Button {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: units.gu(1)
            text: i18n.tr("Cancel")
            onClicked: root.cancel()
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

    function onConfirmed(account) {
        if (account === -2) {
            root.selectedAccount(0)
        } else if (account === -1) {
            setup.exec()
        } else {
            chooseAccount(account)
        }
    }
}
