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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import webbrowserapp.private 0.1
import ".."

Item {
    id: newTabView

    property QtObject bookmarksModel
    property alias historyModel: historyTimeframeModel.sourceModel

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)

    TopSitesModel {
        id: topSitesModel
        sourceModel: HistoryTimeframeModel {
            id: historyTimeframeModel
        }
    }

    QtObject {
        id: internal

        property bool seeMoreBookmarksView: bookmarksCountLimit > 4
        property int bookmarksCountLimit: Math.min(4, numberOfBookmarks)
        property int numberOfBookmarks: bookmarksModel.count !== undefined ?
                                            bookmarksModel.count : 0

        property int numberOfTopSites: historyModel.count !== undefined ?
                                            historyModel.count : 0
    }

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    Flickable {
        anchors.fill: parent
        contentHeight: internal.seeMoreBookmarksView ?
                                          bookmarksColumn.height + units.gu(6) :
                                          contentColumn.height

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                leftMargin: units.gu(1.5)
                right: parent.right
                rightMargin: units.gu(1.5)
            }
            height: childrenRect.height

            Row {
                height: units.gu(6)
                anchors { left: parent.left; right: parent.right }
                spacing: units.gu(1.5)

                Icon {
                    id: starredIcon
                    color: "#dd4814"
                    name: "starred"

                    height: units.gu(2)
                    width: height

                    anchors {
                        leftMargin: units.gu(1)
                        topMargin: units.gu(1)
                        verticalCenter: moreButton.verticalCenter
                    }
                }

                Label {
                    width: parent.width - starredIcon.width - moreButton.width - units.gu(3)
                    anchors.verticalCenter: moreButton.verticalCenter

                    text: i18n.tr("Bookmarks")
                    fontSize: "small"
                }

                Button {
                    id: moreButton
                    height: parent.height - units.gu(2)

                    anchors { top: parent.top; topMargin: units.gu(1) }

                    strokeColor: "#5d5d5d"

                    visible: internal.numberOfBookmarks > 4

                    text: internal.bookmarksCountLimit >= internal.numberOfBookmarks
                    ? i18n.tr("Less") : i18n.tr("More")

                    onClicked: {
                        internal.numberOfBookmarks > internal.bookmarksCountLimit ?
                        internal.bookmarksCountLimit += 5:
                        internal.bookmarksCountLimit = 4;
                    }
                }
            }

            Rectangle {
                height: units.gu(0.1)
                anchors { left: parent.left; right: parent.right }
                color: "#d3d3d3"
            }

            Column {
                id: bookmarksColumn
                anchors {
                    left: parent.left
                    leftMargin: units.gu(-1.5)
                    right: parent.right
                }

                height: units.gu(5) * (internal.bookmarksCountLimit + 1)
                spacing: 0

                UrlDelegate {
                    id: homepageBookmark
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(5)

                    title: i18n.tr('Homepage')

                    url: settings.homepage
                    onItemClicked: newTabView.bookmarkClicked(url)
                }

                UrlsList {
                    id: bookmarksList
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 0
                    limit: internal.bookmarksCountLimit

                    model: newTabView.bookmarksModel

                    onUrlClicked: newTabView.bookmarkClicked(url)
                    onUrlRemoved: newTabView.bookmarkRemoved(url)
                }
            }

            Rectangle {
                height: units.gu(6)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                color: "#f6f6f6"

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: units.gu(1)
                    }

                    opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                    Behavior on opacity { UbuntuNumberAnimation {} }

                    text: i18n.tr("Top sites")
                    fontSize: "small"
                }
            }

            Rectangle {
                height: units.gu(0.1)
                anchors { left: parent.left; right: parent.right }
                color: "#d3d3d3"

                opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation {} }
            }

            Text {
                height: units.gu(6)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                horizontalAlignment: Text.AlignHCenter

                visible: internal.numberOfTopSites === 0

                text: i18n.tr("You haven't visited any site yet")
            }

            UrlsList {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(-1.5)
                    right: parent.right
                }

                opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation {} }

                limit: 10
                spacing: 0

                model: topSitesModel

                onUrlClicked: newTabView.historyEntryClicked(url)
                onUrlRemoved: {
                    newTabView.historyModel.hide(url)
                    limit++;
                }
            }
        }
    }
}
