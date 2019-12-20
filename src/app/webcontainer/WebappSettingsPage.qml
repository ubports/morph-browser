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

import QtQuick 2.4
import QtQuick.Controls 2.2
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import QtWebEngine 1.5
import Morph.Web 0.1
import ".." as Common

FocusScope {
    id: settingsItem

    property QtObject settingsObject

    signal clearCache()
    signal clearAllCookies()
    signal done()
    signal showDownloadsPage()

    Common.BrowserPage {
        title: i18n.tr("WebappContainer Settings")

        anchors.fill: parent
        focus: true

        onBack: settingsItem.done()

        Flickable {
            anchors.fill: parent
            contentHeight: settingsCol.height

            Column {
                id: settingsCol

                width: parent.width

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
                            opacity: (settingsObject.zoomFactor === 1.0) ? 0.5 : 1

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
                    objectName: "downloads"

                    ListItemLayout {
                        title.text: i18n.tr("Downloads")
                        ProgressionSlot {}
                    }

                    onClicked: {
                        showDownloadsPage();
                        done();
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
                        title.text: i18n.tr("Reset webapp settings")
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
