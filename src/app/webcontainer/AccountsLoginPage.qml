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
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.OnlineAccounts 0.1


Item {
    id: root

    property string accountProvider: ""
    property string applicationName: ""

    signal done(variant credentialsId)

    Timer {
        id: checkTimer
        running: true
        repeat: false
        onTriggered: checkAccounts()
        interval: 100
    }

    AccountsModel {
        id: accountsModel
        accountProvider: root.accountProvider
        applicationName: root.applicationName
        onCountChanged: checkAccounts()
        onFinished: { accountsViewLoader.active = true; checkAccounts() }
    }

    Rectangle {
        anchors.fill: parent
        color: "#EEEEEE"
    }

    Loader {
        id: accountsViewLoader
        anchors.fill: parent
        active: false
    }

    function checkAccounts() {
        checkTimer.stop()
        console.log("Accounts: " + accountsModel.count)
        if (accountsModel.count === 0) {
            if (accountsViewLoader.status === Loader.Null) {
                accountsModel.createNewAccount()
                accountsViewLoader.sourceComponent = infoPageComponent
            }
        } else {
            doLogin(accountsModel.model.get(0, "accountServiceHandle"))
        }

        // Note: Disable the account selection for now until we have a clearer view of
        // the design and behavior related to the feature. Keep the code for reference.
        /*
        if (accountsModel.count === 1) {
            doLogin(accountsModel.model.get(0, "accountServiceHandle"))
        } else {
            accountsViewLoader.sourceComponent = accountsSelectionViewComponent
        }
        */
    }

    Component {
        id: infoPageComponent
        Item {
            id: addAccountView

            Label {
                id: label
                anchors.centerIn: parent
                text: i18n.tr("No local account found; an account is needed in order to use this application")
            }

            Button {
                text: i18n.tr("Create an account")

                anchors.top: label.bottom
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: accountsModel.createNewAccount();
            }
        }
    }

    Component {
        id: accountsSelectionViewComponent
        AccountsView {
            id: accountsView

            model: accountsModel.model

            onAccountSelected: doLogin(accountServiceHandle)
        }
    }

    function doLogin(accountHandle) {
        var account = accountComponent.createObject(root, {objectHandle: accountHandle});

        function authenticatedCallback() {
            account.authenticated.disconnect(authenticatedCallback);
            done(account.authData.credentialsId);
        }
        account.authenticated.connect(authenticatedCallback);

        function errorCallback() {
            account.authenticationError.disconnect(errorCallback);
            done(null);
        }
        account.authenticationError.connect(errorCallback);

        account.authenticate(null);
    }

    Component {
        id: accountComponent
        AccountService { }
    }
}


