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
    id: expandedHistoryView

    property alias model: entriesListView.model
    property string expandedDomain: ""
    property int modelPreviousLimit

    signal historyEntryClicked(url url)
    signal backToHistoryClicked()

    Rectangle {
        id: expandedHistoryViewBackground
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: entriesListView

        anchors {
            fill: parent
            margins: units.gu(2)
        }

        spacing: units.gu(1)

        header: Rectangle {
            width: parent.width
            height: units.gu(5)

            MouseArea {
                anchors.fill: parent
                onClicked: backToHistoryClicked()
            }

            Row {
                spacing: units.gu(2)

                UbuntuShape {
                    height: parent.height
                    width: parent.height

                    Image {
                        anchors.fill: parent
                    }
                }

                Label {
                    fontSize: "large"
                    text: i18n.tr("History")
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

            color: expandedHistoryViewBackground.color

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

        delegate: UrlDelegate {
            id: entriesDelegate
            width: parent.width
            height: units.gu(5)

            url: model.url
            title: model.title
            icon: model.icon

            onClicked: historyEntryClicked(model.url)
        }
    }
}
