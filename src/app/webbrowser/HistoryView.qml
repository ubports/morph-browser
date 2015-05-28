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

import QtQuick 2.0
import Ubuntu.Components 1.2
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

            onClicked: historyView.seeMoreEntriesClicked(model.entries)
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

    Item {
        id: topBar

        visible: domainsListView.ViewItems.selectMode
        height: visible ? units.gu(5) : 0

        Behavior on height {
            UbuntuNumberAnimation {}
        }

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Rectangle {
            width: parent.width
            height: parent.height + units.gu(1.5)
            color: "white"
        }

        Item {
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: units.gu(2)
                bottom: parent.bottom
                right: parent.right
                rightMargin: units.gu(2)
            }

            ToolbarAction {
                iconName: "back"
                text: i18n.tr("Cancel")

                MouseArea {
                    anchors.fill: parent
                    onClicked: domainsListView.ViewItems.selectMode = false
                }

                anchors.left: parent.left

                height: parent.height
                width: height
            }

            ToolbarAction {
                iconName: "select"
                text: i18n.tr("Select all")

                MouseArea {
                    anchors.fill: parent
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

                anchors {
                    right: deleteButton.left
                    rightMargin: units.gu(2)
                }

                height: parent.height
                width: height
            }

            ToolbarAction {
                id: deleteButton

                iconName: "delete"
                text: i18n.tr("Delete")
                enabled: domainsListView.ViewItems.selectedIndices.length > 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var domains = []
                        for (var i in domainsListView.ViewItems.selectedIndices) {
                            domains.push(domainsListView.model.get(i))
                        }
                        domainsListView.ViewItems.selectMode = false
                        for (var j in domains) {
                            historyModel.removeEntriesByDomain(domains[j])
                        }
                    }
                }

                anchors.right: parent.right

                height: parent.height
                width: height
            }
        }
    }
}
