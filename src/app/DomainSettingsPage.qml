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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

BrowserPage {
    id: domainSettingsPage

    property bool selectMode

    signal done()

    title: i18n.tr("Domain specific settings")

    showBackAction: !selectMode

    leadingActions: [
        Action {
            objectName: "close"
            iconName: "close"
            onTriggered: domainSettingsPage.selectMode = false
        }
    ]

    trailingActions: [
        Action {
            text: i18n.tr("Select all")
            iconName: "select"
            visible: selectMode
            onTriggered: {
                if (domainSettingsListView.ViewItems.selectedIndices.length === domainSettingsListView.count) {
                    domainSettingsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < domainSettingsListView.count; ++i) {
                        indices.push(i)
                    }
                    domainSettingsListView.ViewItems.selectedIndices = indices
                }
            }
        },
        Action {
            text: i18n.tr("Delete")
            iconName: "delete"
            visible: selectMode
            enabled: domainSettingsListView.ViewItems.selectedIndices.length > 0
            onTriggered: {
                var toDelete = []
                for (var i = 0; i < domainSettingsListView.ViewItems.selectedIndices.length; i++) {
                    var selectedDomainSetting = domainSettingsListView.model.get(domainSettingsListView.ViewItems.selectedIndices[i])
                    toDelete.push(selectedDomainSetting.domain)
                }
                console.log(JSON.stringify(DomainSettingsModel))
                for (var i = 0; i < toDelete.length; i++) {
                    DomainSettingsModel.removeEntry(toDelete[i])
                }
                domainSettingsListView.ViewItems.selectedIndices = []
                domainSettingsPage.selectMode = false
            }
        },
        Action {
            iconName: "edit"
            visible: !selectMode
            enabled: domainSettingsListView.count > 0
            onTriggered: {
                selectMode = true
            }
        }
    ]


    onBack: {
        selectMode = false;
        done();
    }

    ListView {
        id: domainSettingsListView
        anchors.fill: parent
        focus: true
        model: SortFilterModel {
           model: DomainSettingsModel
           sort.order: Qt.AscendingOrder
           sort.property: "domainWithoutSubdomain"
        }

        ViewItems.selectMode: domainSettingsPage.selectMode

        delegate: ListItem {
            id: item
            height: item.ListView.isCurrentItem ? layout.height : units.gu(5)

            MouseArea {
                anchors.fill: parent
                onClicked: domainSettingsListView.currentIndex = index
            }

            SlotsLayout {
                id: layout
                width: parent.width

                mainSlot:

                    Column {

                    spacing: units.gu(2)

                    Label {
                        width: parent.width
                        height: units.gu(1)
                        text: model.domain
                        color: item.ListView.isCurrentItem ? "red" : "blue"
                    }

                    Row {
                        spacing: units.gu(1.5)
                        height: units.gu(1)
                        visible: item.ListView.isCurrentItem

                        Label  {
                            text: i18n.tr("allow custom schemes")
                        }

                        CheckBox {
                            checked: model.allowCustomUrlSchemes
                            onTriggered: DomainSettingsModel.allowCustomUrlSchemes(model.domain, checked)
                        }
                    }


                    Row {
                        spacing: units.gu(1.5)
                        height: units.gu(1)
                        visible: item.ListView.isCurrentItem

                        Label  {
                            text: i18n.tr("allow location access")
                        }

                        CheckBox {
                            checked: model.allowLocation
                            onTriggered: DomainSettingsModel.allowLocation(model.domain, checked)
                        }
                    }

                    Label  {
                        height: units.gu(1)
                        text: i18n.tr("User agent: ") + model.userAgent
                        visible: item.ListView.isCurrentItem
                    }
                    // within one label the check if zoom factor is set could not be properly done
                    Label  {
                        height: units.gu(1)
                        text: i18n.tr("Zoom: ") + Math.round(model.zoomFactor * 100) + "%"
                        visible: item.ListView.isCurrentItem && ! isNaN(model.zoomFactor)
                    }
                    Label  {
                        height: units.gu(1)
                        text: i18n.tr("Zoom: ") + i18n.tr("not set")
                        visible: item.ListView.isCurrentItem && isNaN(model.zoomFactor)
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
                        onTriggered: DomainSettingsModel.removeEntry(model.domain)
                    }
                ]
            }
        }
    }

    Scrollbar {
        flickableItem: domainSettingsListView
    }

    Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: domainSettingsListView.count == 0
        wrapMode: Text.Wrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: i18n.tr("No domain specific settings available")
    }
}
