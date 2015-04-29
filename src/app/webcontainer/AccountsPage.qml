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
import Ubuntu.Components.Popups 1.0
import Ubuntu.OnlineAccounts 0.1
import webcontainer.private 0.1

Page {
    id: root

    property string providerId: ""
    property string applicationId: ""
    property string webappName: ""
    property url webappIcon
    property int credentialsId: -1
    property alias webview: detector.webview
    property alias logoutUrlPattern: detector.logoutUrlPattern
    property alias logoutSelectors: detector.logoutSelectors

    signal accountSelected(var credentialsId)
    signal done(bool successful)

    property string __applicationName: webappName
    property url __applicationIcon: webappIcon
    property string __providerName: providerId
    property var __account: null
    property var __loggedOutAccounts: []
    property var __accountsModel: accountsModel

    visible: true
    anchors.fill: parent

    AccountsLoginPage {
        id: accountsLogin

        anchors.fill: parent
        accountsModel: root.__accountsModel

        onAccountSelected: {
            if (accountId < 0) {
                showSplashScreen()
            } else {
                root.__setupAccount(accountId)
            }
        }
        onDone: root.done(successful)
    }

    AccountsSplashScreen {
        id: splashScreen

        providerName: root.__providerName
        applicationName: root.__applicationName
        iconSource: root.__applicationIcon
        visible: false

        onChooseAccount: root.chooseAccount()
    }

    Loader {
        id: accountChooserLoader
        anchors.fill: parent
    }

    Component {
        id: accountChooserComponent
        AccountChooserDialog {
            id: accountChooser
            applicationName: root.__applicationName
            iconSource: root.__applicationIcon
            providerId: root.providerId
            applicationId: root.applicationId
            accountsModel: root.__accountsModel
            onCancel: accountChooserLoader.sourceComponent = null
            onAccountSelected: {
                accountChooserLoader.sourceComponent = null
                root.__setupAccount(accountId)
            }
        }
    }

    LogoutDetector {
        id: detector
        onLogoutDetected: {
            console.log("Logout detected")
        }
    }

    ApplicationModel {
        id: applicationModel
        service: root.applicationId
    }

    ProviderModel {
        id: providerModel
        applicationId: root.applicationId
    }

    AccountServiceModel {
        id: accountsModel
        provider: root.providerId
        applicationId: root.applicationId
    }

    Component {
        id: accountComponent
        AccountService { }
    }

    function __setupApplicationData() {
        for (var i = 0; i < applicationModel.count; i++) {
            if (applicationModel.get(i, "applicationId") === root.applicationId) {
                var name = applicationModel.get(i, "displayName")
                if (name) root.__applicationName = name
                var icon = applicationModel.get(i, "iconName")
                if (icon) root.__applicationIcon = icon
                break
            }
        }
    }

    function __setupProviderData() {
        for (var i = 0; i < providerModel.count; i++) {
            if (providerModel.get(i, "providerId") === root.providerId) {
                root.__providerName = providerModel.get(i, "displayName")
                break
            }
        }
    }

    Component.onCompleted: {
        __setupApplicationData()
        __setupProviderData()
    }

    function __setupAccount(accountId) {
        console.log("Setup account " + accountId)
        if (__account && accountId === __account.accountId) {
            console.log("Same as current account")
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
        credentialsId = __account ? __account.authData.credentialsId : 0
        console.log("Credentials ID: " + credentialsId)
    }

    function login() {
        console.log("Logging in to " + __account)
        var forceCookieRefresh = false
        var index = __loggedOutAccounts.indexOf(__account.accountId)
        if (index >= 0) {
            forceCookieRefresh = true
            __loggedOutAccounts.splice(index, 1)
        }
        accountsLogin.login(__account, forceCookieRefresh)
    }

    function showSplashScreen() {
        splashScreen.visible = true
    }

    function chooseAccount() {
        accountChooserLoader.sourceComponent = accountChooserComponent
    }
}
