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
import Ubuntu.Components 1.3
import Ubuntu.OnlineAccounts 0.1
import webcontainer.private 0.1

Item {
    id: root

    property alias providerId: accountsLogic.providerId
    property alias applicationId: accountsLogic.applicationId
    property alias accountSwitcher: accountsLogic.accountSwitcher
    property string webappName: ""
    property url webappIcon

    signal accountSelected(string accountDataLocation, bool willMoveCookies)
    signal contextReady()
    signal quitRequested()

    property string __providerName: providerId
    property string __lastAccountDataLocation: ""

    anchors.fill: parent

    AccountsLogic {
        id: accountsLogic

        onSplashScreenRequested: showSplashScreen()
        onAccountSelected: root.__emitAccountSelected(credentialsId, willMoveCookies)
        onContextReady: root.contextReady()
        onQuitRequested: root.quitRequested()
        onErrorScreenRequested: showErrorScreen(message)
    }

    AccountsSplashScreen {
        id: splashScreen

        visible: false
        providerName: root.__providerName
        applicationName: root.webappName
        iconSource: root.webappIcon

        onChooseAccount: root.showAccountSwitcher()
        onQuitRequested: root.quitRequested()
        onSkip: accountsLogic.proceedWithNoAccount()
    }

    // Only temporarily used for bug https://bugs.launchpad.net/bugs/1441873
    AccountErrorScreen {
        id: errorScreen

        visible: false
        onClosed: root.quitRequested()
    }

    Loader {
        id: accountChooserLoader
        anchors.fill: parent
    }

    Component {
        id: accountChooserComponent
        AccountChooserDialog {
            id: accountChooser
            applicationName: root.webappName
            iconSource: root.webappIcon
            providerId: root.providerId
            applicationId: root.applicationId
            accountsModel: accountsLogic.accountsModel
            onCancel: {
                accountChooserLoader.sourceComponent = null
                root.accountSelected(root.__lastAccountDataLocation, false)
            }
            onAccountSelected: {
                accountChooserLoader.sourceComponent = null
                accountsLogic.setupAccount(accountId)
            }
        }
    }

    ProviderModel {
        id: providerModel
        applicationId: root.applicationId
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
        __setupProviderData()
    }

    function showErrorScreen(message) {
        errorScreen.message = message
        errorScreen.visible = true
    }

    function showSplashScreen() {
        splashScreen.visible = true
    }

    function showAccountSwitcher() {
        accountChooserLoader.sourceComponent = accountChooserComponent
    }

    function __emitAccountSelected(credentialsId, willMoveCookies) {
        __lastAccountDataLocation = credentialsId > 0 ? ("/id-" + credentialsId) : ""
        accountSelected(__lastAccountDataLocation, willMoveCookies)
    }

    function setupWebcontextForAccount(webcontext) {
        accountsLogic.setupWebcontextForAccount(webcontext)
    }
}
