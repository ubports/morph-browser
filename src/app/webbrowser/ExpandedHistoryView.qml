/*
 * Copyright 2014-2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import ".."

FocusScope {
    id: expandedHistoryView

    property alias model: entriesListView.model
    property alias count: entriesListView.count

    signal historyEntryClicked(url url)
    signal historyEntryRemoved(url url)
    signal done()

    MouseArea {
        // Prevent click events from propagating through to the view below
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.foreground
    }

    ListView {
        id: entriesListView

        focus: true
        clip: true

        anchors {
            top: header.bottom
            topMargin: units.gu(1.5)
            bottom: parent.bottom
            bottomMargin: units.gu(1.5)
            left: parent.left
            right: parent.right
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            anchors {
                left: parent.left
                leftMargin: units.gu(1.5)
                right: parent.right
            }
        }

        delegate: UrlDelegate {
            id: entriesDelegate
            objectName: "entriesDelegate"
            width: parent.width
            height: units.gu(5)

            url: model.url
            title: model.title
            icon: model.icon

            onClicked: expandedHistoryView.historyEntryClicked(model.url)
            onRemoved: expandedHistoryView.historyEntryRemoved(model.url)
        }

        Keys.onDeletePressed: currentItem.removed()
        Keys.onEscapePressed: done()
    }

    Item {
        id: header
        objectName: "header"

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(8)

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)
            color: theme.palette.normal.base
        }

        UrlDelegate {
            anchors {
                left: parent.left
                right: doneButton.left
                rightMargin: units.gu(1)
                top: parent.top
                topMargin: -units.gu(0.7)
            }
            icon: model ? model.lastVisitedIcon : ""
            title: model ? model.domain : ""
            url: i18n.tr("%1 page", "%1 pages", entriesListView.count).arg(entriesListView.count)
            enabled: false
        }

        Button {
            id: doneButton

            strokeColor: theme.palette.selected.base

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
