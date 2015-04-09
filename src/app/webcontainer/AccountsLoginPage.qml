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

    property var accountsModel

    signal accountSelected(int accountId)
    signal done(bool successful)

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
            // check that the account exists
            for (var i = 0; i < accountsModel.count; i++) {
                if (accountsModel.get(i, "accountId") === settings.selectedAccount) {
                    break;
                }
            }
            if (i >= accountsModel.count) {
                // The selected account was not found
                settings.selectedAccount = -1
            }
        }

        root.accountSelected(settings.selectedAccount)
    }

    function login(account, forceCookieRefresh) {
        console.log("Preparing for login, forced = " + forceCookieRefresh)

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
}


