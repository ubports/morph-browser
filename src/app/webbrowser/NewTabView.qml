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
        property bool seeMoreBookmarksView: false
    }

    ListModel {
        id: sectionsModel

        Component.onCompleted: {
            if (bookmarksListModel && bookmarksListModel.count !== 0)
                sectionsModel.append({ section: "bookmarks" });
            if (historyListModel && historyListModel.count !== 0 && !internal.seeMoreBookmarksView )
                sectionsModel.append({ section: "topsites" });
        }
    }

    LimitProxyModel {
        id: bookmarksListModel

        sourceModel: newTabView.bookmarksModel

        limit: internal.seeMoreBookmarksView ? -1 : internal.bookmarksCountLimit
    }

    LimitProxyModel {
        id: historyListModel

        sourceModel: TopSitesModel {
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

            sourceComponent: { 
                if (modelData == "bookmarks") {
                    if (internal.seeMoreBookmarksView) {
                        return bookmarksFolderComponent
                    } else {
                        return bookmarksComponent
                    }
                }

                return topSitesComponent
            }
        }

        section.property: "section"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: opacity > 0.0 ? sectionHeader.height + units.gu(1) : 0

            opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0

            color: newTabBackground.color

            Behavior on opacity { UbuntuNumberAnimation {} }

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

        UrlsList {
            id: bookmarksList

            width: newTabListView.width
            opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0

            height: opacity == 0.0 ? 0 : childrenRect.height
            model: bookmarksListModel

            footerLabelText: i18n.tr("see more")
            footerLabelVisible: bookmarksListModel.unlimitedCount > internal.bookmarksCountLimit

            onUrlClicked: newTabView.bookmarkClicked(url)
            onUrlRemoved: newTabView.bookmarkRemoved(url)
            onFooterLabelClicked: internal.seeMoreBookmarksView = true
        }
    }

    Component {
        id: bookmarksFolderComponent

        ListView {
            width: newTabListView.width
            opacity: internal.seeMoreBookmarksView ? 1.0 : 0.0

            height: opacity == 0.0 ? 0 : childrenRect.height
            model: BookmarksFolderListModel {
                sourceModel: bookmarksModel
            }

            section.property: "folder"
            section.delegate: Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                height: folderHeader.height
                color: newTabBackground.color

                ListItem.Header {
                    id: folderHeader
                    text: section ? section : i18n.tr("All Bookmarks")
                }
            }

            delegate: UrlsList {
                width: parent.width
                model: entries
                footerLabelVisible: false
                onUrlClicked: newTabView.bookmarkClicked(url)
                onUrlRemoved: newTabView.bookmarkRemoved(url)
            }

            footer: Item {
                width: parent.width
                height: seeLessLabel.height + units.gu(6)

                MouseArea {
                    anchors.centerIn: seeLessLabel

                    width: seeLessLabel.width + units.gu(4)
                    height: seeLessLabel.height + units.gu(4)
                    onClicked: internal.seeMoreBookmarksView = false

                }

                Label {
                    id: seeLessLabel
                    anchors.centerIn: parent
                    font.bold: true
                    text: i18n.tr("see less")
                }
            }
        }
    }

    Component {
        id: topSitesComponent

        UrlsList {
            objectName: "topSitesList"

            width: newTabListView.width
            opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0

            height: opacity == 0.0 ? 0 : childrenRect.height
            model: historyListModel

            footerLabelVisible: false

            onUrlClicked: newTabView.historyEntryClicked(url)
            onUrlRemoved: newTabView.historyModel.hide(url)

            Behavior on opacity { UbuntuNumberAnimation {} }
        }
    }
}
