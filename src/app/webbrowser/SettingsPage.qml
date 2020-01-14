/*
 * Copyright 2015-2016 Canonical Ltd.
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
import QtQuick.Controls 2.2
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import Morph.Web 0.1
import webbrowserapp.private 0.1
import ".." as Common
import "../UrlUtils.js" as UrlUtils

FocusScope {
    id: settingsItem

    property QtObject settingsObject

    signal clearCache()
    signal clearAllCookies()
    signal done()

    SearchEngines {
        id: searchEngines
        searchPaths: searchEnginesSearchPaths
    }

    Common.BrowserPage {
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
                    readonly property url defaultHomepage: "https://start.duckduckgo.com"

                    ListItemLayout {
                        title.text: i18n.tr("Homepage")
                        subtitle.text: (homepageListItem.currentHomepage.toString() === "") ? i18n.tr("New Tab Page") : homepageListItem.currentHomepage
                        Icon {
                            id: resetHomepage
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.homepage.toString() === "") ? 0.3 : 1

                            MouseArea {
                               anchors.fill: parent
                               onClicked: settingsObject.homepage = ""
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
                    }

                    onClicked: PopupUtils.open(homepageDialog)
                }

                ListItem {
                    objectName: "restoreSession"

                    ListItemLayout {
                        title.text: i18n.tr("Restore previous session at startup")
                        subtitle.text: settingsObject.incognitoOnStart ? i18n.tr("not available because of startup in private mode") : ""
                        CheckBox {
                            id: restoreSessionCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.restoreSession = checked
                            enabled: ! settingsObject.incognitoOnStart
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
                            onTriggered: settingsObject.setDesktopMode = checked
                        }
                    }

                    Binding {
                        target: setDesktopModeCheckbox
                        property: "checked"
                        value: settingsObject.setDesktopMode
                    }
                }

                ListItem {
                    objectName: "autoFitToWidthEnabled"

                    ListItemLayout {
                        title.text: i18n.tr("Automatic fit to width")
                        subtitle.text: i18n.tr("Adjusts the width of the website to the window")
                        CheckBox {
                            id: autoFitToWidthEnabledCheckbox
                            SlotsLayout.position: SlotsLayout.Trailing
                            onTriggered: settingsObject.autoFitToWidthEnabled = checked
                        }
                    }

                    Binding {
                        target: autoFitToWidthEnabledCheckbox
                        property: "checked"
                        value: settingsObject.autoFitToWidthEnabled
                    }
                }

                ListItem {
                    objectName: "defaultZoomFactor"

                    ListItemLayout {
                        title.text: i18n.tr("Default Zoom")
                        SpinBox {
                          id: defaultZoomFactorSelector
                          value: Math.round(settingsObject.zoomFactor * 100 * stepSize) / stepSize
                          from: 25
                          to: 500
                          stepSize: 5
                          textFromValue: function(value, locale) {
                            return value + "%";
                          }
                          onValueModified: {
                            settingsObject.zoomFactor = (Math.round(value / stepSize) * stepSize) / 100
                          }
                        }
                        Icon {
                            id: resetZoom
                            name: "reset"

                            height: units.gu(2)
                            width: height
                            opacity: (settingsObject.zoomFactor === 1.0) ? 0.3 : 1

                            MouseArea {
                               anchors.fill: parent
                               onClicked: settingsObject.zoomFactor = 1.0
                            }

                            anchors {
                                leftMargin: units.gu(1)
                                topMargin: units.gu(2)
                            }
                        }
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

                    onClicked: {
                        settingsObject.restoreDefaults();
                        settingsObject.resetDomainPermissions();
                        settingsObject.resetDomainSettings();
                    }
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

            Common.BrowserPage {
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
                                checked: settingsObject.searchEngine === delegateSearchEngine.filename
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

            Common.BrowserPage {
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
                            objectName: "startInPrivateMode"

                            ListItemLayout {
                                title.text: i18n.tr("Start in private mode")
                                CheckBox {
                                    id: startInPrivateModeCheckbox
                                    SlotsLayout.position: SlotsLayout.Trailing
                                    onTriggered: {
                                        settingsObject.incognitoOnStart = checked;
                                        if (checked) {
                                            settingsObject.restoreSession = false;
                                        }
                                    }
                                }
                            }

                            Binding {
                                target: startInPrivateModeCheckbox
                                property: "checked"
                                value: settingsObject.incognitoOnStart
                            }
                        }

                        ListItem {
                            objectName: "setDomainWhiteListMode"

                            ListItemLayout {
                                title.text: i18n.tr("Only allow browsing to whitelisted websites")
                                CheckBox {
                                    id: setDomainWhiteListModeCheckbox
                                    SlotsLayout.position: SlotsLayout.Trailing
                                    onTriggered: settingsObject.domainWhiteListMode = checked
                                }
                            }

                            Binding {
                                target: setDomainWhiteListModeCheckbox
                                property: "checked"
                                value: settingsObject.domainWhiteListMode
                            }
                        }

                        ListItem {
                            objectName: "DomainPermissions"

                            ListItemLayout {
                               title.text: "Domain blacklist/whitelist"
                               ProgressionSlot {}
                           }

                           onClicked: domainPermissionsViewLoader.active = true
                        }

                        ListItem {
                            objectName: "DomainSettings"

                            ListItemLayout {
                               title.text: "Domain specific settings"
                               ProgressionSlot {}
                           }

                           onClicked: domainSettingsViewLoader.active = true
                        }

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
                                title.text: i18n.tr("Clear browsing history")
                            }
                            enabled: HistoryModel.count > 0
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear browsing history?")})
                                dialog.confirmed.connect(HistoryModel.clearAll)
                            }
                        }

                        ListItem {
                            objectName: "privacy.clearCache"
                            ListItemLayout {
                                title.text: i18n.tr("Clear cache")
                            }
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear cache?")});
                                dialog.confirmed.connect(clearCache);
                            }
                        }

                        ListItem {
                            objectName: "privacy.clearAllCookies"
                            ListItemLayout {
                                title.text: i18n.tr("Clear all cookies")
                            }
                            onClicked: {
                                var dialog = PopupUtils.open(privacyConfirmDialogComponent, privacyItem, {"title": i18n.tr("Clear all Cookies?")});
                                dialog.confirmed.connect(clearAllCookies);
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
                if (settingsObject.homepage.toString() === "") {
                    newTabPageOption.checked = true;
                }
                else if (settingsObject.homepage === homepageListItem.defaultHomepage) {
                    defaultHomePageOption.checked = true;
                }
                else {
                    customHomepageOption.checked = true;
                }
            }

            Column {

            Common.CustomizedRadioButton {
                id: newTabPageOption
                text: i18n.tr("New Tab Page")
                color: theme.palette.normal.foregroundText
            }

            Common.CustomizedRadioButton {
                id: defaultHomePageOption
                text: "start.duckduckgo.com"
                color: theme.palette.normal.foregroundText
            }

            Common.CustomizedRadioButton {
                id: customHomepageOption
                text: i18n.tr("Custom hompage")
                color: theme.palette.normal.foregroundText
                onCheckedChanged: {
                if (checked) {
                    homepageTextField.forceActiveFocus()
                    homepageTextField.cursorPosition = homepageTextField.text.length
                }

                }
            }

            TextField {
                id: homepageTextField
                width: parent.width
                objectName: "homepageDialog.text"
                text: settingsObject.homepage
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhUrlCharactersOnly
                enabled: customHomepageOption.checked
                onAccepted: {
                    if (saveButton.enabled) {
                        saveButton.clicked();
                    }
                }
            }

            }

            Button {
                id: saveButton
                objectName: "homepageDialog.saveButton"
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: i18n.tr("Save")
                enabled: UrlUtils.looksLikeAUrl(homepageTextField.text.trim()) || ! customHomepageOption.checked
                color: theme.palette.normal.positive
                onClicked: {
                    if (newTabPageOption.checked) {
                        settingsObject.homepage = "";
                    }
                    else if (defaultHomePageOption.checked) {
                        settingsObject.homepage = homepageListItem.defaultHomepage;
                    }
                    else if (customHomepageOption.checked) {
                        settingsObject.homepage = UrlUtils.fixUrl(homepageTextField.text);
                    }

                    PopupUtils.close(dialogue);
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
        }
    }

    Component {
        id: mediaAccessComponent

        Common.BrowserPage {
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

    Loader {
        id: domainSettingsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DomainSettingsPage.qml")
        }

        Connections {
            target: domainSettingsViewLoader.item
            onDone: domainSettingsViewLoader.active = false
            onReload: {
                domainSettingsViewLoader.active = false
                domainSettingsViewLoader.active = true

                if (selectedDomain) {
                  domainSettingsViewLoader.item.setDomainAsCurrentItem(selectedDomain)
                }
            }
        }
    }

    Loader {
        id: domainPermissionsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DomainPermissionsPage.qml")
        }

        Connections {
            target: domainPermissionsViewLoader.item
            onDone: domainPermissionsViewLoader.active = false
            onReload: {
                domainPermissionsViewLoader.active = false
                domainPermissionsViewLoader.active = true

                if (selectedDomain) {
                  domainPermissionsViewLoader.item.setDomainAsCurrentItem(selectedDomain)
                }
            }
        }
    }
}
