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

    property QtObject historyModel
    property string expandedDomainName: ""

    signal historyEntryClicked(url url)
    signal seeMoreEntriesClicked(LimitProxyModel model)
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
                    sourceModel: historyModel
                }
            }
        }

        section.property: "lastVisitDate"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: sectionHeader.height + units.gu(1)

            color: historyViewBackground.color

            ListItem.Header {
                id: sectionHeader

                text:{
                    var today = new Date()
                    var yesterday = new Date()
                    yesterday.setDate(yesterday.getDate() - 1)

                    if (section === Qt.formatDateTime(today, "yyyy-MM-dd")) {
                        return i18n.tr("Last visited")
                    } else if (section === Qt.formatDateTime(yesterday, "yyyy-MM-dd")) {
                        return i18n.tr("Yesterday")
                    } else {
                        var values = section.split("-", 3)
                        var year = values[0]
                        var month = values[1]
                        var day = values[2]

                        var d = new Date(year, month-1, day)
                        if (parseInt(day) === 1)
                            return Qt.formatDateTime(d, "dddd dd'st' MMMM")
                        if (parseInt(day) === 2)
                            return Qt.formatDateTime(d, "dddd dd'nd' MMMM")
                        if (parseInt(day) === 3)
                            return Qt.formatDateTime(d, "dddd dd'rd' MMMM")
                        else
                            return Qt.formatDateTime(d, "dddd dd'th' MMMM")
                    }
                }
            }
        }

        delegate: Column {
            height: domainsDelegate.height + entriesView.height
            width: parent.width
            clip: true

            LimitProxyModel {
                id: entriesModelLimited
                sourceModel: model.entries
                limit: 3
            }

            UrlDelegate {
                id: domainsDelegate
                width: parent.width
                height: units.gu(5)

                property bool expanded: historyView.expandedDomainName === model.domain

                url: {
                    if (expanded) {
                        if (entriesModelLimited.unlimitedCount === 1)
                            return i18n.tr("1 page")
                        else
                            return i18n.tr("%1 pages").arg(entriesModelLimited.unlimitedCount)
                    } else {
                        return model.lastVisitedTitle
                    }
                }

                title: model.domain
                icon: model.lastVisitedIcon

                onClicked: {
                    if (historyView.expandedDomainName === model.domain)
                        historyView.expandedDomainName = ""
                    else
                        historyView.expandedDomainName = model.domain

                    if (entriesView.domain !== model.domain) {
                        entriesView.domain = model.domain

                        if (entriesModelLimited.unlimitedCount > 3)
                            entriesModelLimited.limit = 2

                        entriesView.limitedModel = entriesModelLimited
                    }
                }
            }

            Item {
                id: entriesView

                property LimitProxyModel limitedModel
                property string domain: ""

                anchors {
                    left: parent.left
                    right: parent.right
                }

                height: 0
                opacity: 0.0

                ListView {
                    id: entriesListView

                    anchors {
                        fill: parent
                        margins: domainsListView.spacing
                    }

                    spacing: domainsListView.spacing

                    model: entriesView.limitedModel

                    interactive: false

                    delegate: UrlDelegate {
                        id: entriesDelegate

                        width: parent.width
                        height: units.gu(5)

                        url: model.url
                        title: model.title ? model.title : model.url
                        icon: model.icon

                        onClicked: historyEntryClicked(model.url)
                    }

                    footer: Rectangle {
                        width: parent.width
                        height: footerLabel.visible ? units.gu(5) : 0

                        MouseArea {
                            width: footerLabel.width + units.gu(4)
                            height: parent.height

                            anchors.centerIn: footerLabel

                            enabled: footerLabel.visible

                            onClicked: seeMoreEntriesClicked(entriesView.limitedModel)
                        }

                        Label {
                            id: footerLabel
                            anchors.centerIn: parent

                            visible: entriesView.limitedModel ? entriesView.limitedModel.unlimitedCount > 3 : false

                            font.bold: true
                            text: i18n.tr("see more")
                        }
                    }
                }

                states: State {
                    name: "expanded"
                    when: (domain !== "") && domain === historyView.expandedDomainName
                    PropertyChanges {
                        target: entriesView
                        height: limitedModel ? limitedModel.count * (units.gu(5) + domainsListView.spacing) + entriesListView.footerItem.height : 0
                        opacity: 1.0
                    }
                }

                transitions: Transition {
                    UbuntuNumberAnimation { properties: "height,opacity" }
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
