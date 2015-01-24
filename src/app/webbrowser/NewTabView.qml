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

        property int bookmarksCountLimit: 5
        property int numberOfBookmarks: bookmarksListModel.count !== undefined ?
                                            bookmarksListModel.unlimitedCount : 0
        property int numberOfTopSites: historyListModel.count !== undefined ?
                                                    historyListModel.count : 0
    }

    ListModel {
        id: sectionsModel

        Component.onCompleted: {
            sectionsModel.append({ section: "bookmarks" });
            sectionsModel.append({ section: "topsites" });
        }
    }

    LimitProxyModel {
        id: bookmarksListModel
        sourceModel: newTabView.bookmarksModel
        limit: internal.bookmarksCountLimit
    }

    LimitProxyModel {
        id: historyListModel
        sourceModel: HistoryByVisitsModel {
            sourceModel: HistoryTimeframeModel {
                sourceModel: newTabView.historyModel
                // We only show sites visited on the last 60 days
                start: {
                    var date = new Date()
                    date.setDate(date.getDate() - 60)
                    return date
                }
            }
        }

        limit: 10
    }

    Rectangle {
        id: newTabBackground
        anchors.fill: parent
        color: "#f6f6f6"
    }

    ListView {
        id: newTabListView
        anchors.fill: parent

        model: sectionsModel

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }

            width: parent.width
            height: children.height

            sourceComponent: modelData == "bookmarks" ? bookmarksComponent :
                                                        topSitesComponent
        }

        section.property: "section"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: (section == "bookmarks" && internal.numberOfBookmarks > 0) ||
                    (section == "topsites" && internal.numberOfTopSites > 0) ?
                                        sectionHeader.height + units.gu(1) : 0
            color: newTabBackground.color

            ListItem.Header {
                id: sectionHeader

                visible: parent.height > 0

                text: {
                    if (section == "bookmarks") {
                        return i18n.tr("Bookmarks")
                    } else if (section == "topsites") {
                        return i18n.tr("Top sites")
                    }
                }
            }

            Button {
                height: parent.height - units.gu(2)

                anchors { right: parent.right; rightMargin: units.gu(2);
                            top: parent.top; topMargin: units.gu(0.3) }

                color: parent.color

                visible: section == "bookmarks" && internal.numberOfBookmarks > 5

                text: internal.bookmarksCountLimit >= internal.numberOfBookmarks
                                            ? i18n.tr("less") : i18n.tr("more")

                onClicked: {
                    internal.numberOfBookmarks > internal.bookmarksCountLimit ?
                            internal.bookmarksCountLimit +=5 :
                            internal.bookmarksCountLimit = 5
                }

            }
        }

        section.labelPositioning: ViewSection.InlineLabels |
                                    ViewSection.CurrentLabelAtStart
    }

    Component {
        id: bookmarksComponent

        BookmarksList {
            width: parent.width

            model: bookmarksListModel

            onBookmarkClicked: newTabView.bookmarkClicked(url)
            onBookmarkRemoved: newTabView.bookmarkRemoved(url)
        }
    }

    Component {
        id: topSitesComponent

        Flow {
            width: parent.width

            spacing: units.gu(1)

            Repeater {
                model: historyListModel

                delegate: MouseArea {
                    width: units.gu(18)
                    height: childrenRect.height

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        //height: childrenRect.height

                        spacing: units.gu(1)

                        Label {
                            width: parent.width
                            height: units.gu(2)

                            fontSize: "small"
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight

                            text: model.title ? model.title : model.url
                        }

                        UbuntuShape {
                            width: parent.width
                            height: units.gu(10)

                            // we need that to clip the background image
                            clip: true

                            Image {
                                source: Qt.resolvedUrl("assets/tab-artwork.png")
                                asynchronous: true
                                width: parent.height
                                height: width
                                opacity: 0.6
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: units.gu(-3)
                                }
                            }
                            Column {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    margins: units.gu(1)
                                }

                                Favicon {
                                    source: model.icon
                                }

                                Label {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    elide: Text.ElideRight
                                    text: model.domain
                                    fontSize: "small"
                                }
                                Label {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                    }
                                    elide: Text.ElideRight
                                    text: model.title
                                    fontSize: "small"
                                }
                            }
                        }
                    }

                    onClicked: historyEntryClicked(model.url)
                }
            }
        }
    }
}
