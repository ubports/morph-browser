/*
 * Copyright 2019 Chris Clime
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

    function setDomainAsCurrentItem(domain) {
        for (var index = 0; index < domainPermissionsListView.count; index++) {
            var domainSetting = domainPermissionsListView.model.get(index);
            if (domainSetting.domain === domain) {
                domainPermissionsListView.currentIndex = index;
                return;
            }
        }
    }

    property QtObject domainPermissionsObject
    property bool selectMode
    property bool sortByLastRequested: false

    signal done()
    signal reload(string selectedDomain)

    BrowserPage {
        id: domainPermissionsPage

        anchors.fill: parent
        focus: true

        title: i18n.tr("Domain blacklist/whitelist")

        showBackAction: !selectMode

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
                onTriggered: selectMode = true
            },
            Action {
                iconName: "add"
                visible: !selectMode

                onTriggered: {
                    var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"), domainPermissionsPage);
                    promptDialog.title = i18n.tr("Add domain");
                    promptDialog.message = i18n.tr("Enter the name of the domain, e.g. example.com (subdomains will be removed).");
                    promptDialog.inputMethodHints = Qt.ImhUrlCharactersOnly | Qt.ImhNoPredictiveText;
                    promptDialog.accept.connect(function(text) {
                        if (text !== "") {
                            var domain = DomainPermissionsModel.getDomainWithoutSubdomain(UrlUtils.extractHost(text));
                            if (DomainPermissionsModel.contains(domain)) {
                                domainPermissionsItem.setDomainAsCurrentItem(domain);
                            }
                            else {
                                DomainPermissionsModel.insertEntry(domain, false);
                                reload(domain);
                            }
                        }
                    });
                }
            },
            Action {
                iconName: sortByLastRequested ? "clock" : "indicator-keyboard-Az"
                visible: !selectMode
                onTriggered: sortByLastRequested = !sortByLastRequested
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
                sort.order: sortByLastRequested ? Qt.DescendingOrder : Qt.AscendingOrder
                sort.property: sortByLastRequested ? "lastRequested" : "domain"
            }

            ViewItems.selectMode: selectMode

            delegate: ListItem {
                id: item
                readonly property bool isCurrentItem: item.ListView.isCurrentItem
                readonly property string domain: model.domain
                height: isCurrentItem ? layout.height : units.gu(5)
                color: isCurrentItem ? ((theme.palette.selected.background.hslLightness > 0.5) ? Qt.darker(theme.palette.selected.background, 1.05) : Qt.lighter(theme.palette.selected.background, 1.5)) : theme.palette.normal.background

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

                        Row {
                            spacing: units.gu(1.5)
                            height: units.gu(1)
                            width: parent.width

                            Icon {
                                visible: (model.permission === DomainPermissionsModel.NotSet)
                                name: "dialog-question-symbolic"
                                height: units.gu(2)
                                width: height
                            }

                            IconWithColorOverlay {
                                overlayColor: theme.palette.normal.positive
                                visible: (model.permission === DomainPermissionsModel.Whitelisted)
                                name: "ok"
                                height: units.gu(2)
                                width: height
                            }

                            IconWithColorOverlay {
                                overlayColor: theme.palette.normal.negative
                                visible: (model.permission === DomainPermissionsModel.Blocked)
                                name: "cancel"
                                height: units.gu(2)
                                width: height
                            }

                            Label {
                                text: model.domain
                                font.bold: item.ListView.isCurrentItem
                                color: theme.palette.normal.foregroundText
                            }

                            Label {
                                visible: (model.requestedByDomain !== "")
                                text:  "(→%1)".arg(model.requestedByDomain)
                                color: theme.palette.normal.foregroundText
                            }

                        }

                        ColumnLayout {
                            visible: item.ListView.isCurrentItem
                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.NotSet)
                                text: i18n.tr("Not Set")
                                color: theme.palette.normal.foregroundText
                                onCheckedChanged: {
                                    if (checked) {
                                        DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.NotSet, false)
                                    }
                                }
                            }
                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.Blocked)
                                text: i18n.tr("Never allow access")
                                color: theme.palette.normal.backgroundText
                                onCheckedChanged: {
                                    if (checked) {
                                        DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.Blocked, false)
                                    }
                                }
                            }

                            CustomizedRadioButton {
                                checked: (model.permission === DomainPermissionsModel.Whitelisted)
                                text: i18n.tr("Always allow access")
                                color: theme.palette.normal.backgroundText
                                onCheckedChanged: {
                                    if (checked) {
                                        DomainPermissionsModel.setPermission(model.domain, DomainPermissionsModel.Whitelisted, false)
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
                            onTriggered: DomainPermissionsModel.removeEntry(model.domain)
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
            text: i18n.tr("No sites have been granted special permissions")
        }
    }
}
