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

    Flickable {
        anchors {
            top: titleDivider.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentHeight: settingsCol.height

        Column {
            id: settingsCol

            width: parent.width

            ListItem.Subtitled {
                text: i18n.tr("Search engine")
                subText: settingsObject.searchEngine

                visible: searchEngineFolder.count > 1

                action: Action {
                    onTriggered: {
                        searchEngineItem.visible = true;
                    }
                }
            }

            ListItem.Subtitled {
                text: i18n.tr("Homepage")
                subText: settingsObject.homepage

                action: Action {
                    onTriggered: PopupUtils.open(homepageDialog)
                }
            }

            ListItem.Standard {
                text: i18n.tr("Restore previous session at startup")
                highlightWhenPressed: false
                control: Switch {
                    checked: settingsObject.restoreSession
                    onClicked: settingsObject.restoreSession = checked;
                }
            }

            ListItem.Standard {
                text: i18n.tr("Allow opening new tabs in background")
                highlightWhenPressed: false
                control: Switch {
                    checked: settingsObject.allowOpenInBackgroundTab === 'true' ||
                        (settingsObject.allowOpenInBackgroundTab === 'default' &&
                            formFactor === "desktop")

                    onClicked:
                        settingsObject.allowOpenInBackgroundTab = checked ? 'true' : 'false';
                }
            }

            ListItem.Standard {
                text: i18n.tr("Privacy")

                action: Action {
                    onTriggered: privacyItem.visible = true;
                }
            }

            ListItem.Standard {
                text: i18n.tr("Reset browser settings")
                onClicked: {
                    settingsObject.restoreDefaults();
                }
            }
        }
    }

    SettingsPageHeader {
        id: title

        onTrigger: settingsItem.done()
        text: i18n.tr("Settings")
    }

    ListItem.Divider {
        id: titleDivider
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
        }
        Rectangle {
            anchors.fill: parent
            color: "#E6E6E6"
        }
    }

    Item {
        id: searchEngineItem
        anchors.fill: parent
        visible: false

        Rectangle {
            anchors.fill: parent
            color: "#f6f6f6"
        }

        ListView {
            anchors {
                top: searchEngineTitleDivider.bottom
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
                        searchEngineItem.visible = false;
                    }
                }
            }
        }

        SettingsPageHeader {
            id: searchEngineTitle

            onTrigger: searchEngineItem.visible = false;
            text: i18n.tr("Search engine")
        }

        ListItem.Divider {
            id: searchEngineTitleDivider
            anchors {
                top: searchEngineTitle.bottom
                left: parent.left
                right: parent.right
            }
            Rectangle {
                anchors.fill: parent
                color: "#E6E6E6"
            }
        }
    }

    Item {
        id: privacyItem
        anchors.fill: parent
        visible: false

        Rectangle {
            anchors.fill: parent
            color: "#f6f6f6"
        }

        Flickable {
            anchors {
                top: privacyTitleDivider.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            contentHeight: privacyCol.height

            Column {
                id: privacyCol
                width: parent.width

                ListItem.Standard {
                    text: i18n.tr("Clear Browsing History")
                    onClicked: historyModel.clearAll();
                    opacity: historyModel.count > 0 ? 1 : 0.5
                }
            }
        }

        SettingsPageHeader {
            id: privacyTitle
            onTrigger: privacyItem.visible = false;
            text: i18n.tr("Privacy")
        }

        ListItem.Divider {
            id: privacyTitleDivider
            anchors {
                top: privacyTitle.bottom
                left: parent.left
                right: parent.right
            }
            Rectangle {
                anchors.fill: parent
                color: "#E6E6E6"
            }
        }
    }

    Component {
        id: homepageDialog
        Dialog {
            id: dialogue
            title: i18n.tr("Homepage")

            TextField {
                id: homepageTextField
                text: settingsObject.homepage
            }

            Button {
                anchors { left: parent.left; right: parent.right }
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue);
            }

            Button {
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

