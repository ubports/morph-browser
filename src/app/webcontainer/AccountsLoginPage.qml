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
import Ubuntu.OnlineAccounts 0.1

Item {
    id: root

    property string providerId: ""
    property string applicationId: ""

    signal accountSelected(var account)
    signal done(bool successful)

    property var __account: null

    Timer {
        id: checkTimer
        running: true
        repeat: false
        onTriggered: checkAccounts()
        interval: 100
    }

    Settings {
        id: settings
        property int selectedAccount: -1
    }

    AccountServiceModel {
        id: accountsModel
        provider: root.providerId
        applicationId: root.applicationId
        onCountChanged: checkAccounts()
    }

    Rectangle {
        anchors.fill: parent
        color: "#EEEEEE"
    }

    Loader {
        id: accountsViewLoader
        anchors.fill: parent
    }

    function checkAccounts() {
        checkTimer.stop()
        console.log("Accounts: " + accountsModel.count)
        if (accountsModel.count === 0) {
            settings.selectedAccount = -1
        } else if (settings.selectedAccount > 0) {
            for (var i = 0; i < accountsModel.count; i++) {
                if (accountsModel.get(i, "accountId") === settings.selectedAccount) {
                    var accountHandle = accountsModel.model.get(i, "accountServiceHandle")
                    __account = accountComponent.createObject(root, {
                        objectHandle: accountHandle
                    })
                    break;
                }
            }
            if (!__account) {
                // The selected account was not found
                settings.selectedAccount = -1
            }
        } else if (settings.selectedAccount === 0) {
            __account = null
        }

        root.accountSelected(__account)
    }

    Component {
        id: accountsAdditionToolbarViewComponent
        Item {
            id: addAccountView

            Label {
                id: label
                anchors.centerIn: parent
                text: i18n.tr("No local account found for ") + root.accountProvider + "."
            }

            Label {
                id: skipLabel
                text: i18n.tr("Skip account creation step")
                color: UbuntuColors.orange
                fontSize: "small"

                anchors.top: label.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                Icon {
                    anchors.left: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: units.dp(12)
                    width: units.dp(12)
                    name: "chevron"
                    color: UbuntuColors.orange
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -units.gu(5)
                    onClicked: root.done(null)
                }
            }

            Panel {
                id: panel
                anchors {
                    right: parent.right
                    left: parent.left
                    bottom: parent.bottom
                }

                locked: true

                height: units.gu(8)

                Rectangle {
                    color: Theme.palette.normal.overlay
                    anchors.fill: parent
                    Item {
                        height: units.gu(8)
                        width: units.gu(8)

                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                        }

                        ToolbarButton {
                            action: Action {
                                text: i18n.tr("Add account")
                                iconSource: Qt.resolvedUrl("/usr/share/icons/ubuntu-mobile/actions/scalable/add.svg")
                                onTriggered: {
                                    accountsModel.createNewAccount();
                                }
                            }
                        }

                        signal clicked()
                        onClicked: {
                            accountsModel.createNewAccount();
                        }
                    }
                }

                Component.onCompleted: panel.open()
            }

        }
    }

    /*
    Component {
        id: accountsSelectionViewComponent
        AccountsView {
            id: accountsView

            model: accountsModel.model

            onAccountSelected: doLogin(accountServiceHandle)
        }
    }
    */

    function login(account, forceCookieRefresh) {
        function authenticatedCallback() {
            console.log("Authenticated!")
            account.authenticated.disconnect(authenticatedCallback)
            root.done(true)
        }
        account.authenticated.connect(authenticatedCallback)

        function errorCallback() {
            console.log("Authentication error!")
            account.authenticationError.disconnect(errorCallback)
            root.done(false)
        }
        account.authenticationError.connect(errorCallback)

        var params = {}
        if (forceCookieRefresh) {
            params["UiPolicy"] = 1 // RequestPasswordPolicy
        }

        account.authenticate(params)
    }

    Component {
        id: accountComponent
        AccountService { }
    }
}


