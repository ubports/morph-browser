/*
 * Copyright 2015-2016 Canonical Ltd.
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
import QtWebEngine 1.5
import webbrowserapp.private 0.1

import "../UrlUtils.js" as UrlUtils

FocusScope {
    id: settingsItem

    property QtObject settingsObject

    signal done()

    SearchEngines {
        id: searchEngines
        searchPaths: searchEnginesSearchPaths
    }

    BrowserPage {
        title: i18n.tr("Settings")

        anchors.fill: parent
        visible: !subpageContainer.visible
        focus: true

        onBack: settingsItem.done()

        Flickable {
            anchors.fill: parent
            contentHeight: settingsCol.height

            Column {
                id: settingsCol

                width: parent.width

                ListItem {
                    id: searchEngineListItem
                    objectName: "searchengine"
                    readonly property string currentSearchEngineDisplayName: currentSearchEngine.name

                    SearchEngine {
                        id: currentSearchEngine
                        searchPaths: searchEngines.searchPaths
                        filename: settingsObject.searchEngine
                    }

                    ListItemLayout {
                        title.text: i18n.tr("Search engine")
                        subtitle.text: searchEngineListItem.currentSearchEngineDisplayName
                        ProgressionSlot {}
                    }

                    visible: searchEngines.engines.count > 1
                    onClicked: searchEngineComponent.createObject(subpageContainer)
                }

                ListItem {
                    id: homepageListItem
                    objectName: "homepage"
                    readonly property url currentHomepage: settingsObject.homepage

                    ListItemLayout {
                        title.text: i18n.tr("Homepage")
                        subtitle.text: homepageListItem.currentHomepage
                    }

                    onClicked: PopupUtils.open(homepageDialog)
                }

                ListItem {
                    objectName: "restoreSession"

                    ListItemLayout {
                        title.text: i18n.tr("Restore previous session at startup")
                        CheckBox {
                            id: restoreSessionCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.restoreSession = checked
                        }
                    }

                    Binding {
                        target: restoreSessionCheckbox
                        property: "checked"
                        value: settingsObject.restoreSession
                    }
                }

                ListItem {
                    objectName: "setDesktopMode"

                    ListItemLayout {
                        title.text: i18n.tr("Set Desktop mode")
                        CheckBox {
                            id: setDesktopModeCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: {
                                settingsObject.setDesktopMode = checked
                                if (checked) {
                                    SharedWebContext.sharedContext.__ua.setDesktopMode(checked)
                                }
                            }
                        }
                    }

                    Binding {
                        target: setDesktopModeCheckbox
                        property: "checked"
                        value: settingsObject.setDesktopMode
                    }
                }

                ListItem {
                    objectName: "privacy"

                    ListItemLayout {
                        title.text: i18n.tr("Privacy & permissions")
                        ProgressionSlot {}
                    }

                    onClicked: privacyComponent.createObject(subpageContainer)
                }

                ListItem {
                    objectName: "reset"

                    ListItemLayout {
                        title.text: i18n.tr("Reset browser settings")
                    }

                    onClicked: settingsObject.restoreDefaults()
                }
            }
        }
    }

    Item {
        id: subpageContainer

        visible: children.length > 0
        anchors.fill: parent

        Component {
            id: searchEngineComponent

            BrowserPage {
                id: searchEngineItem
                objectName: "searchEnginePage"
                anchors.fill: parent

                onBack: searchEngineItem.destroy()
                title: i18n.tr("Search engine")

                ListView {
                    anchors.fill: parent

                    model: searchEngines.engines

                    delegate: ListItem {
                        id: searchEngineDelegate
                        objectName: "searchEngineDelegate"
                        readonly property string displayName: delegateSearchEngine.name
                        SearchEngine {
                            id: delegateSearchEngine
                            searchPaths: searchEngines.searchPaths
                            filename: model.filename
                        }

                        ListItemLayout {
                            title.text: searchEngineDelegate.displayName
                            CheckBox {
                                SlotsLayout.position: SlotsLayout.Trailing
                                checked: settingsObject.searchEngine == delegateSearchEngine.filename
                                onClicked: {
                                    settingsObject.searchEngine = delegateSearchEngine.filename
                                    searchEngineItem.destroy()
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: privacyComponent

            BrowserPage {
                id: privacyItem
                objectName: "privacySettings"

                anchors.fill: parent

                onBack: privacyItem.destroy()
                title: i18n.tr("Privacy & permissions")

                Flickable {
                    anchors.fill: parent
                    contentHeight: privacyCol.height

                    Column {
                        id: privacyCol
                        width: parent.width

                        ListItem {
                            objectName: "privacy.mediaAccess"
                            ListItemLayout {
                                title.text: i18n.tr("Camera & microphone")
                                ProgressionSlot {}
                            }
                            onClicked: mediaAccessComponent.createObject(subpageContainer)
                        }

                        ListItem {
                            objectName: "privacy.clearHistory"
                            ListItemLayout {
                                title.text: i18n.tr("Clear Browsing History")
                            }
                            enabled: HistoryModel.count > 0
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear Browsing History?")})
                                dialog.confirmed.connect(HistoryModel.clearAll)
                            }
                        }

                        ListItem {
                            objectName: "privacy.clearCache"
                            ListItemLayout {
                                title.text: i18n.tr("Clear Cache")
                            }
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
                                color: theme.palette.normal.positive
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

        BrowserPage {
            id: mediaAccessItem
            objectName: "mediaAccessSettings"
            anchors.fill: parent

            onBack: mediaAccessItem.destroy()
            title: i18n.tr("Camera & microphone")

            Flickable {
                anchors.fill: parent
                contentHeight: mediaAccessCol.height

                Column {
                    id: mediaAccessCol
                    width: parent.width

                    ListItem {
                        ListItemLayout {
                            title.text: i18n.tr("Microphone")
                        }
                    }

                    SettingsDeviceSelector {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        isAudio: true
                        visible: devicesCount > 0
                        enabled: devicesCount > 1

                        defaultDevice: settingsObject.defaultAudioDevice
                        onDeviceSelected: {
                            SharedWebContext.sharedContext.defaultAudioCaptureDeviceId = id
                            settingsObject.defaultAudioDevice = id
                        }
                    }

                    ListItem {
                        ListItemLayout {
                            title.text: i18n.tr("Camera")
                        }
                    }

                    SettingsDeviceSelector {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        isAudio: false
                        visible: devicesCount > 0
                        enabled: devicesCount > 1

                        defaultDevice: settingsObject.defaultVideoDevice
                        onDeviceSelected: {
                            SharedWebContext.sharedContext.defaultVideoCaptureDeviceId = id
                            settingsObject.defaultVideoDevice = id
                        }
                    }
                }
            }
        }
    }
}
