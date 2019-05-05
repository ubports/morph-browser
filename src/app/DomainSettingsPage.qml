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

import QtQuick 2.4
import QtWebEngine 1.5
import Ubuntu.Components 1.3
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

BrowserPage {
    id: domainSettingsPage

    title: i18n.tr("Domain specific settings")

    signal done()

    onBack: {
        done()
    }

    //showBackAction: true

    /*
    leadingActions: [
        Action {
            objectName: "close"
            iconName: "close"
            onTriggered: downloadsItem.selectMode = false
        }
    ]
    */


    ListView {
        id: domainSettingsListView
        anchors.fill: parent
        focus: true
        model: DomainSettingsModel

        property int selectedIndex: -1
        /*
        ViewItems.selectMode: downloadsItem.selectMode || downloadsItem.pickingMode
        ViewItems.onSelectedIndicesChanged: {
            if (downloadsItem.multiSelect) {
                return
            }
            // Enforce single selection mode to work around
            // the lack of such a feature in the UITK.
            if (ViewItems.selectedIndices.length > 1 && selectedIndex != -1) {
                var selection = ViewItems.selectedIndices
                selection.splice(selection.indexOf(selectedIndex), 1)
                selectedIndex = selection[0]
                ViewItems.selectedIndices = selection
                return
            }
            if (ViewItems.selectedIndices.length > 0) {
                selectedIndex = ViewItems.selectedIndices[0]
            } else {
                selectedIndex = -1
            }
        }
        */

        delegate:

            ListItem {
            id: item
            height: item.ListView.isCurrentItem ? layout.height : units.gu(5)

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
                        width: parent.width
                        height: units.gu(1)
                        text: model.domain
                        color: item.ListView.isCurrentItem ? "red" : "blue"
                    }

                    Row {
                        spacing: units.gu(1.5)
                        height: units.gu(1)
                        visible: item.ListView.isCurrentItem

                        Label  {
                            text: "allow custom schemes"
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
                            text: "allow location access"
                        }

                        CheckBox {
                            checked: model.allowLocation
                            onTriggered: DomainSettingsModel.allowLocation(model.domain, checked)
                        }
                    }

                    Label  {
                        height: units.gu(1)
                        text: "User agent: " + model.userAgent
                        visible: item.ListView.isCurrentItem
                    }

                    Label  {
                        height: units.gu(1)
                        text: "Zoom factor: " + model.zoomFactor
                        visible: item.ListView.isCurrentItem
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
}
