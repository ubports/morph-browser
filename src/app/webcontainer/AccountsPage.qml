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
import Ubuntu.Components 0.1
import webcontainer.private 0.1

Page {
    id: accountsPage

    property alias accountProvider: accountsLogin.accountProvider
    property alias applicationName: accountsLogin.applicationName
    property var webappCookieStore: null

    signal done()

    visible: false
    anchors.fill: parent

    AccountsLoginPage {
        id: accountsLogin

        anchors.fill: parent

        QtObject {
            id: internal
            function onMoved(result) {
                webappCookieStore.moved.disconnect(internal.onMoved)
                if (!result) {
                    console.error("Unable to move cookies")
                }
                accountsPage.done()
            }
        }

        onDone: {
            if (!accountsPage.visible)
                return
            if (!credentialsId) {
                accountsPage.done()
                return
            }

            if (webappCookieStore) {
                var instance = onlineAccountStoreComponent.createObject(accountsLogin, {accountId: credentialsId})
                webappCookieStore.moved.connect(internal.onMoved)
                webappCookieStore.moveFrom(instance)
            } else {
                accountsPage.done()
            }
        }
    }

    Component {
        id: onlineAccountStoreComponent
        OnlineAccountsCookieStore { }
    }
}
