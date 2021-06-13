/*
 * Copyright 2020 UBports Foundation
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

import QtQuick 2.6
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

BrowserPage {
    id: customUserAgentsPage

    property bool selectMode
    signal done()
    signal reload()

    title: i18n.tr("Custom User Agents")

    showBackAction: !selectMode

    leadingActions: [
        Action {
            objectName: "close"
            iconName: "close"
            onTriggered: customUserAgentsPage.selectMode = false
        }
    ]

    trailingActions: [
        Action {
            text: i18n.tr("Select all")
            iconName: "select"
            visible: selectMode
            onTriggered: {
                if (customUserAgentsListView.ViewItems.selectedIndices.length === customUserAgentsListView.count) {
                    customUserAgentsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < customUserAgentsListView.count; ++i) {
                        indices.push(i)
                    }
                    customUserAgentsListView.ViewItems.selectedIndices = indices
                }
            }
        },
        Action {
            text: i18n.tr("Delete")
            iconName: "delete"
            visible: selectMode
            enabled: customUserAgentsListView.ViewItems.selectedIndices.length > 0
            onTriggered: {
                var toDelete = []
                for (var index = 0; index < customUserAgentsListView.ViewItems.selectedIndices.length; index++) {
                    var selectedUserAgent = customUserAgentsListView.model.get(customUserAgentsListView.ViewItems.selectedIndices[index])
                    toDelete.push(selectedUserAgent.id)
                }
                for (var i = 0; i < toDelete.length; i++) {
                    DomainSettingsModel.removeUserAgentIdFromAllDomains(toDelete[i])
                    UserAgentsModel.removeEntry(toDelete[i])
                }
                customUserAgentsListView.ViewItems.selectedIndices = []
                customUserAgentsPage.selectMode = false
            }
        },
        Action {
            iconName: "edit"
            visible: !selectMode
            enabled: customUserAgentsListView.count > 0
            onTriggered: {
                selectMode = true
            }
        },
        Action {
            iconName: "add"
            visible: !selectMode
            onTriggered: {
                var addDialog = PopupUtils.open(Qt.resolvedUrl("EditCustomUserAgentDialog.qml"), customUserAgentsPage);
                addDialog.title = i18n.tr("New User Agent");
                addDialog.accept.connect(function(userAgentName, userAgentString) {
                            UserAgentsModel.insertEntry(userAgentName, userAgentString);
                            reload();
                });
            }
        }
    ]


    onBack: {
        selectMode = false;
        done();
    }

    ListView {
        id: customUserAgentsListView
        anchors.fill: parent
        focus: true
        model: SortFilterModel {
            id: sortedUserAgentsModel
            model: UserAgentsModel
            sort.property: "name"
            sort.order: Qt.AscendingOrder
        }

        ViewItems.selectMode: customUserAgentsPage.selectMode

        delegate: ListItem {
            id: item

            Label {
                id: userAgentLabel
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height: units.gu(1)
                text: model.name
            }

            leadingActions: deleteActionList

            ListItemActions {
                id: deleteActionList
                actions: [
                    Action {
                        objectName: "leadingAction.delete"
                        iconName: "delete"
                        enabled: true
                        onTriggered: {
                            DomainSettingsModel.removeUserAgentIdFromAllDomains(model.id)
                            UserAgentsModel.removeEntry(model.id)
                        }
                    }
                ]
            }

            trailingActions: trailingActionList

            ListItemActions {
                id: trailingActionList
                actions: [
                    Action {
                        objectName: "trailingActionList.edit"
                        iconName: "edit"
                        enabled: true
                        onTriggered: {
                            var editDialog = PopupUtils.open(Qt.resolvedUrl("EditCustomUserAgentDialog.qml"), customUserAgentsPage);
                            editDialog.title = i18n.tr("Edit User Agent");
                            editDialog.previousUserAgentName = model.name;
                            editDialog.userAgentName = model.name;
                            editDialog.userAgentString = model.userAgentString;
                            editDialog.accept.connect(function(userAgentName, userAgentString) {
                                UserAgentsModel.setUserAgentString(model.id, userAgentString);
                                UserAgentsModel.setUserAgentName(model.id, userAgentName);
                            });
                        }
                    }
                ]
            }
        }
    }

    Scrollbar {
        flickableItem: customUserAgentsListView
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: customUserAgentsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No custom user agents available")
    }
}
