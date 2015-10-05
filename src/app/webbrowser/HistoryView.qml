/*
 * Copyright 2014-2015 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import webbrowserapp.private 0.1

Item {
    id: historyView

    property alias historyModel: historyTimeframeModel.sourceModel

    signal seeMoreEntriesClicked(var model)
    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    ListView {
        id: domainsListView

        anchors {
            top: topBar.bottom
            left: parent.left
            right: parent.right
            bottom: toolbar.top
            rightMargin: units.gu(2)
        }

        model: HistoryDomainListChronologicalModel {
            sourceModel: HistoryDomainListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width - units.gu(2)
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
        }

        delegate: UrlDelegate {
            id: urlDelegate
            width: parent.width
            height: units.gu(5)

            title: model.domain
            url: lastVisitedTitle
            icon: model.lastVisitedIcon

            onClicked: {
                if (selectMode) {
                    selected = !selected
                } else {
                    historyView.seeMoreEntriesClicked(model.entries)
                }
            }
            onRemoved: historyView.historyModel.removeEntriesByDomain(model.domain)
            onPressAndHold: {
                selectMode = !selectMode
                if (selectMode) {
                    domainsListView.ViewItems.selectedIndices = [index]
                }
            }
        }
    }

    Toolbar {
        id: toolbar
        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            strokeColor: UbuntuColors.darkGrey

            text: i18n.tr("Done")

            onClicked: historyView.done()
        }

        ToolbarAction {
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: {
                browser.openUrlInNewTab("", true)
                historyView.done()
            }
        }
    }

    Toolbar {
        id: topBar

        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Label {
            visible: !domainsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(2)
                leftMargin: units.gu(2)
            }

            text: i18n.tr("History")    
        }

        ToolbarAction {
            visible: domainsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                left: parent.left
                leftMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "close"
            text: i18n.tr("Cancel")

            onClicked: domainsListView.ViewItems.selectMode = false
        }

        ToolbarAction {
            visible: domainsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: deleteButton.left
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "select"
            text: i18n.tr("Select all")

            onClicked: {
                if (domainsListView.ViewItems.selectedIndices.length === domainsListView.count) {
                    domainsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < domainsListView.count; ++i) {
                        indices.push(i)
                    }
                    domainsListView.ViewItems.selectedIndices = indices
                }
            }
        }

        ToolbarAction {
            id: deleteButton

            visible: domainsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: parent.right
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "delete"
            text: i18n.tr("Delete")
            enabled: domainsListView.ViewItems.selectedIndices.length > 0

            onClicked: {
                var indices = domainsListView.ViewItems.selectedIndices
                var domains = []
                for (var i in indices) {
                    domains.push(domainsListView.model.get(indices[i]))
                }
                domainsListView.ViewItems.selectMode = false
                for (var j in domains) {
                    historyModel.removeEntriesByDomain(domains[j])
                }
            }
        }

        ListItems.ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
        }
    }
}
