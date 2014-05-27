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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import webbrowserapp.private 0.1

Item {
    id: topSitesView

    property QtObject bookmarksModel
    property QtObject historyModel

    signal bookmarkClicked(url url)
    signal seeMoreBookmarksClicked()
    signal historyEntryClicked(url url)

    onVisibleChanged: {
        if (visible && bookmarksListModel) {
            sectionsModel.clear()
            if (bookmarksListModel.count !== 0)
                sectionsModel.append({ section: "bookmarks" });
            if (historyListModel.count !== 0)
                sectionsModel.append({ section: "topsites" });
        }
    }

    ListModel {
        id: sectionsModel
    }

    BookmarksChronologicalMaxCountModel {
        id: bookmarksListModel

        sourceModel: BookmarksChronologicalModel {
            sourceModel: topSitesView.bookmarksModel
        }
        maxCount: 5
    }

    HistoryByVisitsMaxCountModel {
        id: historyListModel

        sourceModel: HistoryByVisitsModel {
            sourceModel: HistoryTimeframeModel {
                sourceModel: topSitesView.historyModel
                // We only show sites visited on the last 60 days
                start: {
                    var date = new Date()
                    date.setDate(date.getDate() - 60)
                    date.setHours(0)
                    date.setMinutes(0)
                    date.setSeconds(0)
                    date.setMilliseconds(0)
                    return date
                }
                end: {
                    var date = new Date()
                    date.setDate(date.getDate())
                    date.setHours(23)
                    date.setMinutes(59)
                    date.setSeconds(59)
                    date.setMilliseconds(999)
                    return date
                }
            }
        }

        maxCount: 10
    }

    Rectangle {
        id: topSitesBackground
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: topSitesListView

        anchors.fill: parent

        model: sectionsModel

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

        BookmarksList {
            model: bookmarksListModel

            footerLabelText: i18n.tr("see more")

            onBookmarkClicked: topSitesView.bookmarkClicked(url)
            onFooterLabelClicked: topSitesView.seeMoreBookmarksClicked()
        }
    }

    Component {
        id: topSitesComponent

        Flow {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }

            width: parent.width

            spacing: units.gu(1)

            Repeater {
                model: historyListModel

                delegate: PageDelegate{
                    width: units.gu(18)
                    height: units.gu(25)

                    url: model.url
                    label: model.title ? model.title : model.url

                    onClicked: historyEntryClicked(model.url)
                }
            }
        }
    }
}
