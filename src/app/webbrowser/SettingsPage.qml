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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Components.ListItems 1.0 as ListItem

import "urlManagement.js" as UrlManagement

Item {
    id: settings

    property QtObject historyModel

    signal restoreDefaults()
    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
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
                subText: browser.searchEngine
                visible: false

                action: Action {
                    onTriggered: {
                        searchEngineItem.visible = true;
                    }
                }
            }

            ListItem.Subtitled {
                text: i18n.tr("Homepage")
                subText: browser.homepage

                action: Action {
                    onTriggered: PopupUtils.open(homepageDialog)
                }
            }

            ListItem.Standard {
                text: i18n.tr("Restore previous session at startup")
                highlightWhenPressed: false
                control: Switch {
                    checked: browser.restoreSession
                    onClicked: browser.restoreSession = checked;
                }
            }

            ListItem.Standard {
                text: i18n.tr("Allow opening new tabs in background")
                highlightWhenPressed: false
                control: Switch {
                    checked: browser.allowOpenInBackgroundTab
                    onClicked: browser.allowOpenInBackgroundTab = checked;
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
                showDivider: false
                onClicked: {
                    settings.restoreDefaults();
                }
            }
        }
    }

    ListItem.Empty {
        id: title
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        Rectangle {
            anchors.fill: parent
            color: "#f6f6f6"
        }

        showDivider: false
        highlightWhenPressed: false

        AbstractButton {
            id: backButton
            width: height

            onTriggered: settings.done()
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
            }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
                color: "#E6E6E6"
                visible: parent.pressed
            }

            Icon {
                name: "back"
                anchors {
                    fill: parent
                    topMargin: units.gu(2)
                    bottomMargin: units.gu(2)
                }
            }
        }

        Label {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: backButton.right
                topMargin: units.gu(2)
                bottomMargin: units.gu(2)
            }
            text: i18n.tr("Settings")
        }
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
            anchors.fill: parent
            model: 5
            delegate: ListItem.Standard {
                text: index
                action: Action {
                    onTriggered: {
                        browser.searchEngine = text;
                        searchEngineItem.visible = false;
                    }
                }
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

        ListItem.Empty {
            id: privacyTitle
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            Rectangle {
                anchors.fill: parent
                color: "#f6f6f6"
            }

            highlightWhenPressed: false
            showDivider: false

            AbstractButton {
                id: privacyBackButton
                width: height

                onTriggered: privacyItem.visible = false;

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: units.gu(1)
                    anchors.rightMargin: units.gu(1)
                    color: "#E6E6E6"
                    visible: parent.pressed
                }

                Icon {
                    name: "back"
                    anchors {
                        fill: parent
                        topMargin: units.gu(2)
                        bottomMargin: units.gu(2)
                    }
                }
            }

            Label {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: privacyBackButton.right
                    topMargin: units.gu(2)
                    bottomMargin: units.gu(2)
                }
                text: i18n.tr("Privacy")
            }
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
                text: browser.homepage
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
                    browser.homepage = UrlManagement.fixUrl(homepageTextField.text);
                    PopupUtils.close(dialogue);
                }
            }
        }
    }
}

