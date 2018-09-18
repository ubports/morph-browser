/*
 * Copyright 2015 Canonical Ltd.
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
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import webcontainer.private 0.1

Item {
    id: root

    property alias providerId: accountsModelObject.provider
    property alias applicationId: accountsModelObject.applicationId
    property bool accountSwitcher: false
    property var accountsModel: accountsModelObject

    signal splashScreenRequested()
    signal errorScreenRequested(string message)
    signal accountSelected(int credentialsId, bool willMoveCookies)
    signal contextReady()
    signal quitRequested()

    property var __account: null
    property int __credentialsId: __account ? __account.authData.credentialsId : 0

    Timer {
        id: checkTimer
        running: true
        repeat: false
        onTriggered: checkAccounts()
        interval: 100
    }

    AccountServiceModel {
        id: accountsModelObject
    }

    // This is only used if accountSwitcher is false
    Setup {
        id: setup
        applicationId: root.applicationId
        providerId: root.providerId
        onFinished: {
            if ("accountId" in reply) {
                root.checkAccounts()
            } else if ("errorName" in reply) {
                root.errorScreenRequested(i18n.tr("Account window could not be opened. You can only create one account at a time; please try again after closing all other account windows."))
            } else {
                root.quitRequested()
            }
        }
    }

    Settings {
        id: settings
        property int selectedAccount: -1
        property string initializedAccounts: "[]"
    }

    Component {
        id: accountComponent
        AccountService { }
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }

    Component {
        id: oxideCookieStoreComponent
        ChromeCookieStore { }
    }

    function checkAccounts() {
        checkTimer.stop()
        console.log("Accounts: " + accountsModel.count)

        /* If account switching is not supported, we just pick the first
         * account here. */
        if (!accountSwitcher) {
            if (accountsModel.count === 0) {
                setup.exec()
            } else {
                settings.selectedAccount = accountsModel.get(0, "accountId")
                setupAccount(settings.selectedAccount)
            }
            return
        }

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

        if (settings.selectedAccount < 0) {
            splashScreenRequested()
        } else {
            setupAccount(settings.selectedAccount)
        }
    }

    function proceedWithNoAccount() {
        __account = null
        settings.selectedAccount = 0
        accountSelected(__credentialsId, false)
    }

    function setupAccount(accountId) {
        console.log("Setup account " + accountId)
        if (__account && accountId === __account.accountId) {
            console.log("Same as current account")
            accountSelected(__credentialsId, false)
            return
        }
        __account = null
        for (var i = 0; i < accountsModel.count; i++) {
            if (accountsModel.get(i, "accountId") === accountId) {
                var accountHandle = accountsModel.get(i, "accountServiceHandle")
                __account = accountComponent.createObject(root, {
                    objectHandle: accountHandle
                })
                break;
            }
        }
        console.log("Credentials ID: " + __credentialsId)
        settings.selectedAccount = accountId
        accountSelected(__credentialsId, mustMoveCookies(accountId))
    }

    function login(account, callback) {
        console.log("Preparing for login")

        function authenticatedCallback() {
            console.log("Authenticated!")
            account.authenticated.disconnect(authenticatedCallback)
            callback(true)
        }
        account.authenticated.connect(authenticatedCallback)

        function errorCallback() {
            console.log("Authentication error!")
            account.authenticationError.disconnect(errorCallback)
            callback(false)
        }
        account.authenticationError.connect(errorCallback)

        account.authenticate(null)
    }

    function mustMoveCookies(accountId) {
        var initializedAccounts
        try {
            initializedAccounts = JSON.parse(settings.initializedAccounts)
        } catch(e) {
            initializedAccounts = []
        }
        return initializedAccounts.indexOf(accountId) < 0
    }

    function rememberCookiesMoved(accountId) {
        var initializedAccounts = JSON.parse(settings.initializedAccounts)
        if (initializedAccounts.indexOf(accountId) < 0) {
            initializedAccounts.push(accountId)
            settings.initializedAccounts = JSON.stringify(initializedAccounts)
        }
    }

    function onCookiesMoved(result) {
        if (!result) {
            console.log("Cookies were not moved")
        } else {
            console.log("cookies moved")
        }
        // Even if the cookies were not moved, we don't want to retry
        rememberCookiesMoved(__account.accountId)
        contextReady()
    }

    function setupWebcontextForAccount(webcontext) {
        if (!__account || !mustMoveCookies(__account.accountId)) {
            contextReady()
            return
        }

        login(__account, function(authenticated) {
            if (!authenticated) {
                errorScreenRequested(i18n.tr("Authentication failed"))
            } else {
                console.log("Authentication succeeded, moving cookies")
                var accountsCookieStore = onlineAccountStoreComponent.createObject(root, {
                    "accountId": __credentialsId
                })

                var webappCookieStore = oxideCookieStoreComponent.createObject(root, {
                    "oxideStoreBackend": webcontext.cookieManager,
                    "dbPath": webcontext.dataPath + "/cookies.sqlite"
                })

                webappCookieStore.moved.connect(onCookiesMoved)
                webappCookieStore.moveFrom(accountsCookieStore)
            }
        })
    }
}
