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

import QtQuick 2.4
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Web 0.2
import webbrowserapp.private 0.1

import "../UrlUtils.js" as UrlUtils

Item {
    id: settingsItem

    property QtObject historyModel
    property QtObject settingsObject

    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    SearchEngines {
        id: searchEngines
        searchPaths: searchEnginesSearchPaths
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

            ListItems.Subtitled {
                objectName: "searchengine"

                SearchEngine {
                    id: currentSearchEngine
                    searchPaths: searchEngines.searchPaths
                    filename: settingsObject.searchEngine
                }

                text: i18n.tr("Search engine")
                subText: currentSearchEngine.name

                visible: searchEngines.engines.count > 1

                onClicked: searchEngineComponent.createObject(subpageContainer)
            }

            ListItems.Subtitled {
                objectName: "homepage"

                text: i18n.tr("Homepage")
                subText: settingsObject.homepage

                onClicked: PopupUtils.open(homepageDialog)
            }

            ListItems.Standard {
                objectName: "restoreSession"

                text: i18n.tr("Restore previous session at startup")
                highlightWhenPressed: false

                control: CheckBox {
                    id: restoreSessionCheckbox
                    onTriggered: settingsObject.restoreSession = checked
                }

                Binding {
                    target: restoreSessionCheckbox
                    property: "checked"
                    value: settingsObject.restoreSession
                }
            }

            ListItems.Standard {
                objectName: "backgroundTabs"

                text: i18n.tr("Allow opening new tabs in background")
                highlightWhenPressed: false

                control: CheckBox {
                    id: allowOpenInBackgroundTabCheckbox
                    onTriggered: settingsObject.allowOpenInBackgroundTab = checked ? 'true' : 'false'
                }

                Binding {
                    target: allowOpenInBackgroundTabCheckbox
                    property: "checked"
                    value: settingsObject.allowOpenInBackgroundTab === 'true' ||
                           (settingsObject.allowOpenInBackgroundTab === 'default' && formFactor === "desktop")
                }
            }

            ListItems.Standard {
                objectName: "privacy"

                text: i18n.tr("Privacy")

                onClicked: privacyComponent.createObject(subpageContainer)
            }

            ListItems.Standard {
                objectName: "reset"

                text: i18n.tr("Reset browser settings")

                onClicked: settingsObject.restoreDefaults()
            }

            ListItems.Standard {
                objectName: "mediaAccess"

                text: i18n.tr("Media Access")

                onClicked: mediaAccessComponent.createObject(subpageContainer)
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
                objectName: "searchEnginePage"
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: "#f6f6f6"
                }

                SettingsPageHeader {
                    id: searchEngineTitle

                    onBack: searchEngineItem.destroy()
                    text: i18n.tr("Search engine")
                }

                ListView {
                    anchors {
                        top: searchEngineTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    clip: true

                    model: searchEngines.engines

                    delegate: ListItems.Standard {
                        objectName: "searchEngineDelegate_" + index
                        SearchEngine {
                            id: searchEngineDelegate
                            searchPaths: searchEngines.searchPaths
                            filename: model.filename
                        }
                        text: searchEngineDelegate.name

                        control: CheckBox {
                            checked: settingsObject.searchEngine == searchEngineDelegate.filename
                            onClicked: {
                                settingsObject.searchEngine = searchEngineDelegate.filename
                                searchEngineItem.destroy()
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
                    onBack: privacyItem.destroy()
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

                        ListItems.Standard {
                            objectName: "privacy.clearHistory"
                            text: i18n.tr("Clear Browsing History")
                            enabled: historyModel.count > 0
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear Browsing History?")})
                                dialog.confirmed.connect(historyModel.clearAll)
                            }
                        }

                        ListItems.Standard {
                            objectName: "privacy.clearCache"
                            text: i18n.tr("Clear Cache")
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear Cache?")})
                                dialog.confirmed.connect(function() {
                                    enabled = false;
                                    CacheDeleter.clear(cacheLocation + "/Cache2", function() { enabled = true });
                                })
                            }
                        }
                    }
                }

                Component {
                    id: privacyConfirmDialogComponent

                    Dialog {
                        id: privacyConfirmDialog
                        objectName: "privacyConfirmDialog"
                        signal confirmed()

                        Row {
                            spacing: units.gu(2)
                            anchors {
                                left: parent.left
                                right: parent.right
                            }

                            Button {
                                objectName: "privacyConfirmDialog.cancelButton"
                                width: (parent.width - parent.spacing) / 2
                                text: i18n.tr("Cancel")
                                onClicked: PopupUtils.close(privacyConfirmDialog)
                            }

                            Button {
                                objectName: "privacyConfirmDialog.confirmButton"
                                width: (parent.width - parent.spacing) / 2
                                text: i18n.tr("Clear")
                                color: UbuntuColors.green
                                onClicked: {
                                    confirmed()
                                    PopupUtils.close(privacyConfirmDialog)
                                }
                            }
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

            Component.onCompleted: {
                homepageTextField.forceActiveFocus()
                homepageTextField.cursorPosition = homepageTextField.text.length
            }

            TextField {
                id: homepageTextField
                objectName: "homepageDialog.text"
                text: settingsObject.homepage
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                onAccepted: {
                    if (UrlUtils.looksLikeAUrl(text)) {
                        settingsObject.homepage = UrlUtils.fixUrl(text)
                        PopupUtils.close(dialogue)
                    }
                }
            }

            Button {
                objectName: "homepageDialog.cancelButton"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }

            Button {
                objectName: "homepageDialog.saveButton"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Save")
                enabled: UrlUtils.looksLikeAUrl(homepageTextField.text.trim())
                color: "#3fb24f"
                onClicked: {
                    settingsObject.homepage = UrlUtils.fixUrl(homepageTextField.text)
                    PopupUtils.close(dialogue)
                }
            }
        }
    }

    Component {
        id: mediaAccessComponent

        Item {
            id: mediaAccessItem
            objectName: "mediaAccessPage"
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "#f6f6f6"
            }

            SettingsPageHeader {
                id: mediaAccessTitle

                onBack: mediaAccessItem.destroy()
                text: i18n.tr("Allowed domains")
            }

            Flickable {
                anchors {
                    top: mediaAccessTitle.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                clip: true

                contentHeight: mediaAccessCol.height

                Column {
                    id: mediaAccessCol
                    width: parent.width

                    ListItems.Standard {
                        text: i18n.tr("Microphone")
                    }

                    ListItems.Standard {
                        objectName: "mediaAccess.audioOrigins"
                        text: i18n.tr("Allowed domains")
                        progression: true
                        onClicked: {
                            mediaAccessOriginsComponent.createObject(subpageContainer, {isAudio: true})
                        }
                    }

                    ListItems.Standard {
                        text: i18n.tr("Camera")
                    }

                    ListItems.Standard {
                        objectName: "mediaAccess.videoOrigins"
                        text: i18n.tr("Allowed domains")
                        progression: true
                        onClicked: {
                            mediaAccessOriginsComponent.createObject(subpageContainer, {isAudio: false})
                        }
                    }
                }
            }
        }
    }

    Component {
        id: mediaAccessOriginsComponent

        Item {
            id: mediaAccessOriginsItem
            objectName: "mediaAccessOriginsPage"
            anchors.fill: parent

            property bool isAudio: true

            Rectangle {
                anchors.fill: parent
                color: "#f6f6f6"
            }

            SettingsPageHeader {
                id: mediaAccessOriginsTitle

                onBack: mediaAccessOriginsItem.destroy()
                text: isAudio ? i18n.tr("Microphone allowed domains")
                              : i18n.tr("Camera allowed domains")
            }

            ListView {
                objectName: "mediaAccessList"
                anchors {
                    top: mediaAccessOriginsTitle.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                clip: true

                model: SortFilterModel {
                    model: MediaAccessModel
                    filter.property: "permissionsSet"
                    filter.pattern: isAudio ? /a/ : /v/
                    sort.property: "origin"
                    sort.order: Qt.AscendingOrder
                }

                delegate: ListItem {
                    objectName: "mediaAccessDelegate_" + index

                    contentItem.anchors {
                        leftMargin: units.gu(1)
                        rightMargin: units.gu(1)
                    }

                    Label {
                        objectName: "originLabel"
                        text: model.origin
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    Switch {
                        objectName: "permissionSwitch"
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        checked: isAudio ? model.audio : model.video
                        function trigger() {
                            if (isAudio) MediaAccessModel.set(model.origin, !checked, undefined)
                            else MediaAccessModel.set(model.origin, undefined, !checked)
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                objectName: "leadingAction.delete"
                                iconName: "delete"
                                onTriggered: MediaAccessModel.unset(model.origin, isAudio, !isAudio)
                            }
                        ]
                    }
                }
            }
        }
    }
}

