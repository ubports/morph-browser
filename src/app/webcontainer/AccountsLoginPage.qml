/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.OnlineAccounts 0.1

Item {
    id: root

    property string accountProvider: ""
    property string applicationName: ""

    signal done(variant credentialId)

    AccountsModel {
        id: accountsModel
        accountProvider: accountProvider
        applicationName: applicationName
        Component.onCompleted: {
            if (accountsModel.model.count === 0) {
                if (accountProvider.length !== 0) {
                    // TODO propose account creation
                }

                // TODO proper value
                done(null);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#EEEEEE"
    }

    Loader {
        id: accountsSelectionViewLoader
        anchors.fill: parent
        sourceComponent: accountsModel.model.count !== 0 && accountProvider.length !== 0 ? accountsSelectionViewComponent: undefined
    }

    Component {
        id: accountsSelectionViewComponent
        AccountsView {
            model: accountsModel.model

            function accountItemDataRequestedDelegate(accountServiceHandle) {
                var instance = accountComponent.createObject(root, {objectHandle: accountServiceHandle});
                return instance;
            }

            onAccountSelected: {
                var account = accountServiceHandle;
                account.authenticated.connect(function () {
                    done(account.authData.credentialsId);
                });
                account.authenticationError.connect(function () {
                    done(null);
                });
                account.authenticate(null);
            }
        }
    }

    Component {
        id: accountComponent
        AccountService { }
    }
}


