/*
 * Copyright 2014 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Components.Popups 1.0
import webbrowserapp.private 0.1

Item {
    id: historyView

    property alias historyModel: historyTimeframeModel.sourceModel

    signal seeMoreEntriesClicked(var model)
    signal historyDomainRemoved(var domain)
    signal done()

    Rectangle {
        anchors.fill: parent
    }

    ListView {
        id: domainsListView

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: toolbar.top
            margins: units.gu(2)
        }

        spacing: units.gu(2)

        model: HistoryDomainListChronologicalModel {
            sourceModel: HistoryDomainListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width
        }

        delegate: UrlDelegate {
            width: parent.width
            height: units.gu(3)

            title: model.domain
            url: lastVisitedTitle
            icon: model.lastVisitedIcon

            removable: true

            onClicked: historyView.seeMoreEntriesClicked(model.entries)
            onItemRemoved: historyView.historyDomainRemoved(model.domain)
        }
    }

    Toolbar {
        id: toolbar

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(7)

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            color: "white"

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

            text: i18n.tr("Clear")

            iconName: "delete"

            enabled: domainsListView.count > 0

            onClicked: PopupUtils.open(confirmClearComponent)

            Component {
                id: confirmClearComponent

                Dialog {
                    id: confirmClearDialog

                    text: i18n.tr("Delete all history?")

                    Button {
                        text: i18n.tr("Yes")
                        color: UbuntuColors.orange
                        onClicked: {
                            PopupUtils.close(confirmClearDialog)
                            historyView.historyModel.clearAll()
                        }
                    }

                    Button {
                        text: i18n.tr("No")
                        color: UbuntuColors.warmGrey
                        onClicked: PopupUtils.close(confirmClearDialog)
                    }
                }
            }
        }
    }
}
