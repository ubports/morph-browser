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
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1
import "UrlUtils.js" as UrlUtils

FocusScope {
    id: domainSettingsItem

    Settings {
        id:settings
     property string homepage2: "hello"
    }

    property QtObject domainSettingsObject
    property bool selectMode

    signal done()
    signal reload(string selectedDomain)

    BrowserPage {
        id: domainSettingsPage

        anchors.fill: parent
        focus: true

        title: i18n.tr("Domain specific settings")

        showBackAction: !selectMode

        function setDomainAsCurrentItem(domain) {
            for (var index = 0; index < domainSettingsListView.count; index++) {
                var domainSetting = domainSettingsListView.model.get(index);
                if (domainSetting.domain === domain) {
                    domainSettingsListView.currentIndex = index;
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
                    for (var index = 0; index < domainSettingsListView.ViewItems.selectedIndices.length; index++) {
                        var selectedDomainSetting = domainSettingsListView.model.get(domainSettingsListView.ViewItems.selectedIndices[index])
                        toDelete.push(selectedDomainSetting.domain)
                    }
                    console.log(JSON.stringify(DomainSettingsModel))
                    for (var i = 0; i < toDelete.length; i++) {
                        DomainSettingsModel.removeEntry(toDelete[i])
                    }
                    domainSettingsListView.ViewItems.selectedIndices = []
                    selectMode = false
                }
            },
            Action {
                iconName: "edit"
                visible: !selectMode
                enabled: domainSettingsListView.count > 0
                onTriggered: {
                    selectMode = true
                }
            },
            Action {
                iconName: "add"
                visible: !selectMode

                onTriggered: {
                    var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"), domainSettingsPage);
                    promptDialog.title = i18n.tr("Add domain")
                    promptDialog.message = i18n.tr("Add the name of the domain, e.g. m.example.com")
                    promptDialog.accept.connect(function(text) {
                        if (text !== "") {
                            var domain = UrlUtils.extractHost(text)
                            if (DomainSettingsModel.contains(domain)) {
                                domainSettingsPage.setDomainAsCurrentItem(domain);
                            }
                            else {
                                DomainSettingsModel.insertEntry(domain);
                                reload(domain);
                            }
                        }
                    });
                }
            }
        ]

        onBack: {
            selectMode = false;
            domainSettingsItem.done();
        }

        DomainSettingsSortedModel {
            id: domainSettingsSortedModel
            model: DomainSettingsModel
            sortOrder: Qt.AscendingOrder
        }

        ListItem {
            id: useragentsMenu
            z: 3
            height: units.gu(6)
            color: theme.palette.normal.background
            ListItemLayout {
                title.text: i18n.tr("Custom User Agents")
                ProgressionSlot {}
            }

            onClicked: customUserAgentsViewLoader.active = true
        }

        ListView {
            id: domainSettingsListView
            anchors.topMargin: units.gu(5)
            anchors.fill: parent
            focus: true
            model:  SortFilterModel {
                model: domainSettingsSortedModel
            }

            ViewItems.selectMode: selectMode

            delegate: ListItem {
                id: item
                readonly property bool isCurrentItem: item.ListView.isCurrentItem
                readonly property string domain: model.domain
                readonly property int userAgentId: model.userAgentId
                height: isCurrentItem ? layout.height : units.gu(5)
                color: isCurrentItem ? theme.palette.selected.base : theme.palette.normal.background

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
                            id: domainLabel
                            width: parent.width
                            height: units.gu(1)
                            text: model.domain
                            font.bold: item.ListView.isCurrentItem
                        }

                        Row {
                            spacing: units.gu(1.5)
                            height: units.gu(1)
                            visible: item.ListView.isCurrentItem

                            Label  {
                                text: i18n.tr("allow custom schemes" + settings.homepage2)
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
                                onTriggered: {
                                    DomainSettingsModel.allowLocation(model.domain, checked);
                                }
                            }
                        }

                        Row {
                            spacing: units.gu(1.5)
                            height: units.gu(1)
                            visible: item.ListView.isCurrentItem

                            Label  {
                                text: i18n.tr("custom user agent")
                                opacity: UserAgentsModel.count > 0 ? 1.0 : 0.5
                            }

                            CheckBox {
                                id: customUserAgentCheckbox
                                enabled: UserAgentsModel.count > 0
                                checked: model.userAgentId > 0
                                onTriggered: {
                                    optSelect.selectedIndex = -1;

                                    if (checked) {
                                        optSelect.currentlyExpanded = true;
                                    }
                                    else  {
                                        DomainSettingsModel.setUserAgentId(model.domain, 0);
                                    }
                                }
                            }
                        }

                        /* ToDo: Can we do sth. about the following log messages ?
                               file:///usr/lib/arm-linux-gnueabihf/qt5/qml/Ubuntu/Components/1.3/OptionSelector.qml:330:13:
                               QML ListView: Binding loop detected for property "itemHeight"
                            */
                        OptionSelector {

                            id: optSelect
                            visible: customUserAgentCheckbox.checked

                            model: SortFilterModel {
                                id: sortedUserAgentsModel
                                model: UserAgentsModel
                                sort.property: "name"
                                sort.order: Qt.AscendingOrder
                            }
                            delegate: OptionSelectorDelegate {
                                text: model.name
                            }

                            function updateIndex() {
                                for (var i = 0; i < model.count; ++i) {
                                    if (item.userAgentId === model.get(i).id)
                                    {
                                        selectedIndex = i;
                                    }
                                }
                            }

                            Connections {
                                target: item

                                onIsCurrentItemChanged: {
                                    if (item.isCurrentItem && (item.userAgentId > 0)) {
                                        optSelect.updateIndex();
                                    }
                                }
                            }

                            onDelegateClicked: {
                                DomainSettingsModel.setUserAgentId(item.domain, model.get(index).id);
                            }
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
            id: scrollBar
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

        Connections {
            target: UserAgentsModel
            enabled: ! customUserAgentsViewLoader.active
            // the OptionSelector does not properly update the model (duplicate entries instead of new user agents)
            onRowCountChanged: reload()
        }
    }

    Loader {
        id: customUserAgentsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("CustomUserAgentsPage.qml")
        }

        Connections {
            target: customUserAgentsViewLoader.item
            onDone: {
                customUserAgentsViewLoader.active = false;
                domainSettingsItem.reload();
            }
            onReload: {
                customUserAgentsViewLoader.active = false;
                customUserAgentsViewLoader.active = true;

                if (selectedUserAgent) {
                    customUserAgentsViewLoader.item.setUserAgentAsCurrentItem(selectedUserAgent)
                }
            }
        }
    }
}
