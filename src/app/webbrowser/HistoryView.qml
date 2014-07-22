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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import webbrowserapp.private 0.1

Item {
    id: historyView

    property alias historyModel: historyTimeframeModel.sourceModel
    property string expandedDomain: ""

    signal historyEntryClicked(url url)
    signal seeMoreEntriesClicked(var model)
    signal done()

    Rectangle {
        id: historyViewBackground
        anchors.fill: parent
        color: "white"
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

        spacing: units.gu(1)

        model: HistoryDomainListChronologicalModel {
            sourceModel: HistoryDomainListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }
        }

        section.property: "lastVisitDate"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: childrenRect.height + units.gu(1)

            color: historyViewBackground.color

            ListItem.Header {
                text: {
                    var today = new Date()
                    var yesterday = new Date()
                    yesterday.setDate(yesterday.getDate() - 1)
                    var sectionDate = new Date(section)
                    if ((sectionDate.getFullYear() == today.getFullYear()) &&
                        (sectionDate.getMonth() == today.getMonth())) {
                        var dayDifference = sectionDate.getDate() - today.getDate()
                        if (dayDifference == 0) {
                            return i18n.tr("Last Visited")
                        } else if (dayDifference == -1) {
                            return i18n.tr("Yesterday")
                        }
                    }
                    return Qt.formatDate(sectionDate, Qt.DefaultLocaleLongDate)
                }
            }
        }

        delegate: Column {
            height: childrenRect.height
            width: parent.width
            clip: true
            spacing: units.gu(1)

            LimitProxyModel {
                id: truncatedModel
                sourceModel: model.entries
                limit: 2
            }

            property bool expanded: model.domain && (historyView.expandedDomain === model.domain)

            UrlDelegate {
                width: parent.width
                height: units.gu(5)

                url: parent.expanded ? ((truncatedModel.unlimitedCount === 1) ? i18n.tr("1 page") : i18n.tr("%1 pages").arg(truncatedModel.unlimitedCount)) : model.lastVisitedTitle
                title: model.domain
                icon: model.lastVisitedIcon

                onClicked: historyView.expandedDomain = (parent.expanded ? "" : model.domain)
            }

            Loader {
                sourceComponent: parent.expanded ? entriesViewComponent : undefined

                width: parent.width
                height: childrenRect.height

                Component {
                    id: entriesViewComponent

                    Column {
                        width: parent ? parent.width : 0
                        height: childrenRect.height
                        spacing: units.gu(1)

                        Repeater {
                            model: (truncatedModel.unlimitedCount > 3) ? truncatedModel : truncatedModel.sourceModel
                            delegate: UrlDelegate {
                                width: parent.width
                                height: units.gu(5)

                                url: model.url
                                title: model.title ? model.title : model.url
                                icon: model.icon

                                onClicked: historyView.historyEntryClicked(model.url)
                            }
                        }

                        MouseArea {
                            width: parent.width
                            height: units.gu(2)
                            enabled: truncatedModel.unlimitedCount > 3
                            visible: enabled

                            Label {
                                anchors.centerIn: parent
                                font.bold: true
                                text: i18n.tr("see more")
                            }

                            onClicked: historyView.seeMoreEntriesClicked(truncatedModel.sourceModel)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: toolbar

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: units.gu(7)

        Rectangle {
            anchors.fill: parent
            color: "#312f2c"
            opacity: 0.8
        }

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            color: "#312f2c"

            text: i18n.tr("Done")

            onClicked: historyView.done()
        }
    }
}
