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
import Ubuntu.Components.ListItems 1.3 as ListItem
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

    SearchEngines {
        id: searchEngines
        searchPaths: searchEnginesSearchPaths
    }

    BrowserPageHeader {
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

            ListItem.Subtitled {
                objectName: "homepage"

                text: i18n.tr("Homepage")
                subText: settingsObject.homepage

                onClicked: PopupUtils.open(homepageDialog)
            }

            ListItem.Standard {
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

            ListItem.Standard {
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

            ListItem.Standard {
                objectName: "privacy"

                text: i18n.tr("Privacy")

                onClicked: privacyComponent.createObject(subpageContainer)
            }

            ListItem.Standard {
                objectName: "reset"

                text: i18n.tr("Reset browser settings")

                onClicked: settingsObject.restoreDefaults()
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

                BrowserPageHeader {
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

                    delegate: ListItem.Standard {
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

                BrowserPageHeader {
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

                        ListItem.Standard {
                            objectName: "privacy.clearHistory"
                            text: i18n.tr("Clear Browsing History")
                            enabled: historyModel.count > 0
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear Browsing History?")})
                                dialog.confirmed.connect(historyModel.clearAll)
                            }
                        }

                        ListItem.Standard {
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
                    if (UrlManagement.looksLikeAUrl(text)) {
                        settingsObject.homepage = UrlManagement.fixUrl(text)
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
                enabled: UrlManagement.looksLikeAUrl(homepageTextField.text.trim())
                color: "#3fb24f"
                onClicked: {
                    settingsObject.homepage = UrlManagement.fixUrl(homepageTextField.text)
                    PopupUtils.close(dialogue)
                }
            }
        }
    }
}

