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

    signal historyRemoved()
    signal restoreDefaults()
    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    ListItem.Empty {
        id: title
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        highlightWhenPressed: false

        Icon {
            id: backButton
            name: "back"

            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                margins: units.gu(2)
            }

            width: height

            MouseArea {
                anchors.fill: parent

                onClicked: settings.done()
            }
        }

        Label {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: backButton.right
                margins: units.gu(2)
            }
            text: i18n.tr("Settings")
        }
    }

    Column {
        anchors {
            top: title.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

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
            text: i18n.tr("Restore old session on startup")
            highlightWhenPressed: false
            control: Switch {
                checked: browser.restoreSession
                onClicked: browser.restoreSession = checked;
            }
        }

        ListItem.Standard {
            text: i18n.tr("Open new tab in background")
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

        ListItem.Empty {
            id: privacyTitle
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            highlightWhenPressed: false

            Icon {
                id: privacyBackButton
                name: "back"

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    margins: units.gu(2)
                }

                width: height

                MouseArea {
                    anchors.fill: parent

                    onClicked: privacyItem.visible = false;
                }
            }

            Label {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: privacyBackButton.right
                    margins: units.gu(2)
                }
                text: i18n.tr("Privacy")
            }
        }

        Column {
            anchors {
                top: privacyTitle.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            ListItem.Standard {
                text: i18n.tr("Clear Browsing History")
                onClicked: {
                    settings.historyRemoved();
                    opacity = 0.5
                }
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

