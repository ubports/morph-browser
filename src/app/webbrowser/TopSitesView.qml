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
        id: topSitesBackground
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: topSites

        anchors.fill: parent

        model: ListModel {
            ListElement { section: "bookmarks" }
            ListElement { section: "topsites" }
        }

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: children.height

            sourceComponent: modelData == "bookmarks" ? bookmarksComponent : topSitesComponent
        }

        section.property: "section"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: sectionHeader.height + units.gu(1)
            color: topSitesBackground.color

            ListItem.Header {
                id: sectionHeader
                text: {
                    if (section == "bookmarks") {
                        return i18n.tr("Bookmarks")
                    } else if (section == "topsites") {
                        return i18n.tr("Top sites")
                    }
                }
            }
        }

        section.labelPositioning: ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart
    }

    Component {
        id: bookmarksComponent

        ListView {
            id: bookmarksList

            property string topViewSection: modelData

            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }

            width: parent.width
            height: contentHeight

            spacing: units.gu(1)

            interactive: false

            model: BookmarksChronologicalModel {
                sourceModel: topSitesView.bookmarksModel
            }

            delegate: UrlDelegate{
                width: parent.width
                height: units.gu(5)

                favIcon: model.icon
                label: model.title ? model.title : model.url
                url: model.url

                onClicked: bookmarkClicked(model.url)
            }
        }
    }

    Component {
        id: topSitesComponent

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
                    //start: {
                    //    var date = new Date()
                    //    //date.setDate(1)
                    //    date.setHours(0)
                    //    date.setMinutes(0)
                    //    date.setSeconds(0)
                    //    date.setMilliseconds(0)
                    //    return date
                    //}
                    //end: {
                    //    var date = new Date()
                    //    date.setDate(date.getDate() - 8)
                    //    //date.setHours(23)
                    //    date.setMinutes(59)
                    //    date.setSeconds(59)
                    //    date.setMilliseconds(999)
                    //    return date
                    //}
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
