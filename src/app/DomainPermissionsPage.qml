/*
 * Copyright 2019 ubports.
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
import Qt.labs.settings 1.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1
import "UrlUtils.js" as UrlUtils

FocusScope {
    id: domainPermissionsItem

    property QtObject domainPermissionsObject
    property bool selectMode

    signal done()
    signal reload(string selectedDomain)

    BrowserPage {
        id: domainPermissionsPage

        anchors.fill: parent
        focus: true

        title: i18n.tr("Domain specific permissions")

        showBackAction: !selectMode

        function setDomainAsCurrentItem(domain) {
            for (var index = 0; index < domainPermissionsListView.count; index++) {
                var domainSetting = domainPermissionsListView.model.get(index);
                if (domainSetting.domain === domain) {
                    domainPermissionsListView.currentIndex = index;
                    return;
                }
            }
        }
        leadingActions: [
            Action {
                objectName: "close"
                iconName: "close"
                onTriggered: selectMode = false
            }
        ]

        trailingActions: [
            Action {
                text: i18n.tr("Select all")
                iconName: "select"
                visible: selectMode
                onTriggered: {
                    if (domainPermissionsListView.ViewItems.selectedIndices.length === domainPermissionsListView.count) {
                        domainPermissionsListView.ViewItems.selectedIndices = []
                    } else {
                        var indices = []
                        for (var i = 0; i < domainPermissionsListView.count; ++i) {
                            indices.push(i)
                        }
                        domainPermissionsListView.ViewItems.selectedIndices = indices
                    }
                }
            },
            Action {
                text: i18n.tr("Delete")
                iconName: "delete"
                visible: selectMode
                enabled: domainPermissionsListView.ViewItems.selectedIndices.length > 0
                onTriggered: {
                    var toDelete = []
                    for (var index = 0; index < domainPermissionsListView.ViewItems.selectedIndices.length; index++) {
                        var selectedDomainSetting = domainPermissionsListView.model.get(domainPermissionsListView.ViewItems.selectedIndices[index])
                        toDelete.push(selectedDomainSetting.domain)
                    }
                    for (var i = 0; i < toDelete.length; i++) {
                        DomainPermissionsModel.removeEntry(toDelete[i])
                    }
                    domainPermissionsListView.ViewItems.selectedIndices = []
                    selectMode = false
                }
            },
            Action {
                iconName: "edit"
                visible: !selectMode
                enabled: domainPermissionsListView.count > 0
                onTriggered: {
                    selectMode = true
                }
            },
            Action {
                iconName: "add"
                visible: !selectMode

                onTriggered: {
                    var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"), domainPermissionsPage);
                    promptDialog.title = i18n.tr("Add domain")
                    promptDialog.message = i18n.tr("Add the name of the domain, e.g. m.example.com")
                    promptDialog.accept.connect(function(text) {
                        if (text !== "") {
                            var domain = UrlUtils.extractHost(text)
                            if (DomainPermissionsModel.contains(domain)) {
                                domainPermissionsPage.setDomainAsCurrentItem(domain);
                            }
                            else {
                                DomainPermissionsModel.insertEntry(domain);
                                reload(domain);
                            }
                        }
                    });
                }
            }
        ]

        onBack: {
            selectMode = false;
            domainPermissionsItem.done();
        }

        ListView {
            id: domainPermissionsListView
            anchors.fill: parent
            focus: true
            model:  SortFilterModel {
                model: DomainPermissionsModel
                sort.order: Qt.AscendingOrder
                sort.property: "domain"
            }

            ViewItems.selectMode: selectMode

            delegate: ListItem {
                id: item
                readonly property bool isCurrentItem: item.ListView.isCurrentItem
                readonly property string domain: model.domain
                height: isCurrentItem ? layout.height : units.gu(5)
                color: isCurrentItem ? theme.palette.selected.base : theme.palette.normal.background

                MouseArea {
                    anchors.fill: parent
                    onClicked: domainPermissionsListView.currentIndex = index
                }

                SlotsLayout {
                    id: layout
                    width: parent.width

                    mainSlot:

                        Column {

                        spacing: units.gu(2)

                        Label {
                            id: domainLabel
                            width: parent.width
                            height: units.gu(1)
                            text: model.domain
                            font.bold: item.ListView.isCurrentItem
                            color: (model.permission === DomainPermissionsModel.Blocked) ? theme.palette.normal.negative :
                                   (model.permission === DomainPermissionsModel.Whitelisted) ? theme.palette.normal.positive : theme.palette.normal.foregroundText
                        }


                        ColumnLayout {
                            visible: item.ListView.isCurrentItem
                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.NotSet)
                                text: "Not Set"
                                color: theme.palette.normal.foregroundText
                                onCheckedChanged: {
                                    if (checked) {
                                    DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.NotSet)
                                    }
                                }
                            }
                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.Blocked)
                                text: "Blocked"
                                font.bold: true
                                color: theme.palette.normal.negative
                                onCheckedChanged: {
                                    if (checked) {
                                    DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.Blocked)
                                    }
                                }
                            }

                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.Whitelisted)
                                text: "Whitelisted"
                                font.bold: true
                                color: theme.palette.normal.positive
                                onCheckedChanged: {
                                    if (checked) {
                                    DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.Whitelisted)
                                    }
                                }
                            }
                        }
                    }
                }

                leadingActions: deleteActionList

                ListItemActions {
                    id: deleteActionList
                    actions: [
                        Action {
                            objectName: "leadingAction.delete"
                            iconName: "delete"
                            enabled: true
                            onTriggered: domainPermissionsModel.removeEntry(model.domain)
                        }
                    ]
                }
            }
        }

        Scrollbar {
            id: scrollBar
            flickableItem: domainPermissionsListView
        }

        Label {
            id: emptyLabel
            anchors.centerIn: parent
            visible: domainPermissionsListView.count == 0
            wrapMode: Text.Wrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: i18n.tr("No domain specific permissions available")
        }
    }
}
