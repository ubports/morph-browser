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

Loader {
    id: root

    property string providerId: ""
    property string applicationId: ""
    property bool accountSwitcher: false
    property string webappName: ""
    property url webappIcon

    signal accountSelected(string accountDataLocation, bool willMoveCookies)
    signal contextReady()
    signal quitRequested()

    function setupWebcontextForAccount(webcontext) {
        if (item) {
            item.setupWebcontextForAccount(webcontext)
        } else {
            root.contextReady()
        }
    }

    function showAccountSwitcher() {
        if (item) item.showAccountSwitcher()
    }

    Component.onCompleted: {
        if (providerId.length === 0) {
            accountSelected("", false)
        } else {
            setSource("AccountsPage.qml", {
                "providerId": providerId,
                "applicationId": applicationId,
                "accountSwitcher": accountSwitcher,
                "webappName": webappName,
                "webappIcon": webappIcon,
            })
        }
    }

    Connections {
        target: item
        onAccountSelected: root.accountSelected(accountDataLocation, willMoveCookies)
        onContextReady: root.contextReady()
        onQuitRequested: root.quitRequested()
    }
}
