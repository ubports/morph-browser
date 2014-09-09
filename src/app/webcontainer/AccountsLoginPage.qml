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

        if (accountsModel.count === 0) {
            // Skip the account creation step for now (see the Note below)
//            accountsViewLoader.sourceComponent = accountsAdditionToolbarViewComponent
            done(null);
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


