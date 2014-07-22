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
import ".."

Item {
    id: expandedHistoryView

    property alias model: entriesListView.model

    signal historyEntryClicked(url url)
    signal done()

    Rectangle {
        id: expandedHistoryViewBackground
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: entriesListView

        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }

        spacing: units.gu(2)

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width
        }

        delegate: UrlDelegate {
            id: entriesDelegate
            width: parent.width
            height: units.gu(3)

            url: model.url
            title: model.title
            icon: model.icon

            onClicked: historyEntryClicked(model.url)
        }
    }

    Rectangle {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(7)

        color: "#f7f7f7"

        UrlDelegate {
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: doneButton.left
                rightMargin: units.gu(1)
                verticalCenter: parent.verticalCenter
            }
            icon: expandedHistoryView.model.lastVisitedIcon
            title: expandedHistoryView.model.domain
            url: i18n.tr("%1 page", "%1 pages", entriesListView.count).arg(entriesListView.count)
        }

        Button {
            id: doneButton

            color: "#f7f7f7"

            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            text: i18n.tr("Less")

            onClicked: expandedHistoryView.done()
        }
    }
}
