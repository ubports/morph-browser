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
    property QtObject historyModel

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)

    QtObject {
        id: internal

        property bool seeMoreBookmarksView: numberOfBookmarks > bookmarksCountLimit
        property int bookmarksCountLimit: 4
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
        contentHeight: contentColumn.height - parent.height
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
                height: units.gu(4)
                anchors { left: parent.left; right: parent.right }
                spacing: units.gu(1.5)

                Icon {
                    id: starredIcon
                    color: "#dd4814"
                    name: "starred"

                    height: units.gu(3)
                    width: height

                    anchors {
                        leftMargin: units.gu(1)
                        verticalCenter: moreButton.verticalCenter
                    }
                }

                Text {
                    width: parent.width - starredIcon.width - moreButton.width - units.gu(3)
                    anchors.verticalCenter: moreButton.verticalCenter

                    text: i18n.tr("Bookmarks")
                }

                Button {
                    id: moreButton
                    height: parent.height - units.gu(0.5)

                    anchors { top: parent.top; topMargin: units.gu(0.25) }

                    strokeColor: "#5d5d5d"

                    visible: internal.numberOfBookmarks > 4

                    text: internal.bookmarksCountLimit >= internal.numberOfBookmarks
                    ? i18n.tr("less") : i18n.tr("more")

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
                color: "#acacac"
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(-1.5)
                    right: parent.right
                }

                height: units.gu(5) + units.gu(5) * Math.min(internal.bookmarksCountLimit, internal.numberOfBookmarks)
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

                    model: newTabView.bookmarksModel

                    onUrlClicked: newTabView.bookmarkClicked(url)
                    onUrlRemoved: newTabView.bookmarkRemoved(url)
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: opacity == 0.0 ? 0 : childrenRect.height

                color: "#f6f6f6"
                opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation {} }

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(1.5)

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }

                        spacing: units.gu(-3)

                        Text {
                            height: units.gu(6)
                            anchors { left: parent.left; right: parent.right }
                            text: i18n.tr("Top sites")
                        }

                        Rectangle {
                            height: units.gu(0.1)
                            anchors { left: parent.left; right: parent.right }
                            color: "#acacac"
                        }
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
                        width: parent.width
                        opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0

                        height: opacity == 0.0 ? 0 : childrenRect.height
                        model: newTabView.historyModel

                        onUrlClicked: newTabView.historyEntryClicked(url)
                        onUrlRemoved: newTabView.historyModel.hide(url)
                    }
                }
            }
        }
    }
}
