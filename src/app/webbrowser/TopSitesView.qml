/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components.ListItems 0.1 as ListItem
import webbrowserapp.private 0.1

Item {
    id: topSitesView

    property QtObject bookmarksModel
    property QtObject historyModel

    signal bookmarkClicked(url url)
    signal historyEntryClicked(url url)

    Rectangle {
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: topSites
        anchors.fill: parent

        model: 1

        header: Column {
            width: parent.width
            height: bookmarksListHeader.height + bookmarksList.contentHeight + (2 * spacing)

            spacing: units.gu(2)

            ListItem.Header {
                id: bookmarksListHeader
                text: i18n.tr("Bookmarks")
            }

            ListView {
                id: bookmarksList
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }

                width: parent.width
                height: parent.height

                spacing: units.gu(1)

                interactive: false

                model: BookmarksChronologicalModel {
                    sourceModel: topSitesView.bookmarksModel
                }

                delegate: UrlDelegate{
                    width: parent.width
                    height: units.gu(5)

                    favIcon: model.icon
                    url: model.url
                    label: model.title ? model.title : model.url

                    onClicked: bookmarkClicked(model.url)
                }
            }
        }

        delegate: Column {
            width: parent.width
            height: units.gu(30)
            spacing: units.gu(2)

            ListItem.Header {
                id: header
                text: i18n.tr("Top sites")
            }

            GridView {
                id: topSitesGrid

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }

                width: parent.width
                height: contentHeight

                cellWidth: units.gu(12)
                cellHeight: units.gu(16)

                interactive: false

                model: HistoryByVisitsModel {
                    sourceModel: HistoryTimeframeModel {
                        sourceModel: topSitesView.historyModel
                        /*
                        start: {
                            var date = new Date()
                            //date.setDate(1)
                            date.setHours(0)
                            date.setMinutes(0)
                            date.setSeconds(0)
                            date.setMilliseconds(0)
                            return date
                        }
                        end: {
                            var date = new Date()
                            date.setDate(date.getDate() - 8)
                            //date.setHours(23)
                            date.setMinutes(59)
                            date.setSeconds(59)
                            date.setMilliseconds(999)
                            return date
                        }
                        */
                    }
                }

                delegate: PageDelegate{
                    width: units.gu(10)
                    height: units.gu(10)

                    url: model.url
                    label: model.title ? model.title : model.url

                    onClicked: historyEntryClicked(model.url)
                }
            }
        }
    }
}
