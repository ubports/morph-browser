/*
 * Copyright 2015 Canonical Ltd.
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
import Qt.labs.folderlistmodel 2.1
import Qt.labs.settings 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Web 0.2
import webbrowserapp.private 0.1

import "urlManagement.js" as UrlManagement

Item {
    id: settingsItem

    property QtObject historyModel
    property Settings settingsObject

    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    FolderListModel {
        id: searchEngineFolder
        folder: dataLocation +"/searchengines"
        showDirs: false
        nameFilters: ["*.xml"]
        sortField: FolderListModel.Name
    }

    SettingsPageHeader {
        id: title

        onBack: settingsItem.done()
        text: i18n.tr("Settings")
        visible: !subpageContainer.visible
    }

    Flickable {
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        visible: !subpageContainer.visible
        clip: true
        contentHeight: settingsCol.height

        Column {
            id: settingsCol

            width: parent.width

            ListItem.Subtitled {
                SearchEngine {
                    id: currentSearchEngine
                    filename: settingsObject.searchEngine
                }
                text: i18n.tr("Search engine")
                subText: currentSearchEngine.name

                visible: searchEngineFolder.count > 1

                onClicked: searchEngineComponent.createObject(subpageContainer);
            }

            ListItem.Subtitled {
                objectName: "homepage"

                text: i18n.tr("Homepage")
                subText: settingsObject.homepage

                onClicked: PopupUtils.open(homepageDialog)
            }

            ListItem.Standard {
                text: i18n.tr("Restore previous session at startup")
                highlightWhenPressed: false

                control: Switch {
                    id: restoreSessionSwitch
                    onClicked: settingsObject.restoreSession = checked;
                }

                Binding {
                    target: restoreSessionSwitch; property: "checked";
                    value: settingsObject.restoreSession
                }
            }

            ListItem.Standard {
                text: i18n.tr("Allow opening new tabs in background")
                highlightWhenPressed: false

                control: Switch {
                    id: allowOpenInBackgroundTabSwitch

                    onClicked: settingsObject.allowOpenInBackgroundTab = checked ? 'true' : 'false';
                }

                Binding {
                    target: allowOpenInBackgroundTabSwitch; property: "checked";
                    value: settingsObject.allowOpenInBackgroundTab === 'true' ||
                    (settingsObject.allowOpenInBackgroundTab === 'default' &&
                        formFactor === "desktop")
                }
            }

            ListItem.Standard {
                objectName: "privacy"

                text: i18n.tr("Privacy")

                onClicked: privacyComponent.createObject(subpageContainer);
            }

            ListItem.Standard {
                text: i18n.tr("Reset browser settings")
                onClicked: settingsObject.restoreDefaults();
            }
        }
    }

    Item {
        id: subpageContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: searchEngineComponent

            Item {
                id: searchEngineItem
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: "#f6f6f6"
                }

                SettingsPageHeader {
                    id: searchEngineTitle

                    onBack: searchEngineItem.destroy();
                    text: i18n.tr("Search engine")
                }

                ListView {
                    anchors {
                        top: searchEngineTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }

                    model: searchEngineFolder

                    delegate: ListItem.Standard {
                        SearchEngine {
                            id: searchEngineDelegate
                            filename: model.fileBaseName
                        }
                        text: searchEngineDelegate.name

                        control: CheckBox {
                            checked: settingsObject.searchEngine == searchEngineDelegate.filename;
                            onClicked: {
                                settingsObject.searchEngine = searchEngineDelegate.filename;
                                searchEngineItem.destroy();
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: privacyComponent

            Item {
                id: privacyItem
                objectName: "privacySettings"

                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: "#f6f6f6"
                }

                SettingsPageHeader {
                    id: privacyTitle
                    onBack: privacyItem.destroy();
                    text: i18n.tr("Privacy")
                }

                Flickable {
                    anchors {
                        top: privacyTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }

                    clip: true

                    contentHeight: privacyCol.height

                    Column {
                        id: privacyCol
                        width: parent.width

                        ListItem.Standard {
                            text: i18n.tr("Clear Browsing History")
                            onClicked: historyModel.clearAll();
                            enabled: historyModel.count > 0
                        }
                    }
                }
            }
        }
    }

    Component {
        id: homepageDialog

        Dialog {
            id: dialogue
            objectName: "homepageDialog"

            title: i18n.tr("Homepage")

            TextField {
                id: homepageTextField
                objectName: "homepageDialog.text"
                text: settingsObject.homepage
            }

            Button {
                objectName: "homepageDialog.cancelButton"
                anchors { left: parent.left; right: parent.right }
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue);
            }

            Button {
                objectName: "homepageDialog.saveButton"
                anchors { left: parent.left; right: parent.right }
                text: i18n.tr("Save")
                color: "#3fb24f"
                onClicked: {
                    settingsObject.homepage = UrlManagement.fixUrl(homepageTextField.text);
                    PopupUtils.close(dialogue);
                }
            }
        }
    }
}

