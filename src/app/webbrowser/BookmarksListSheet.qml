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

Rectangle {
    property QtObject bookmarksModel

    signal bookmarkRequested(url url)
    signal seeLessBookmarksRequested()

    Rectangle {
        id: bookmarksListBackground
        anchors.fill: parent
        color: "white"
    }

    ListView {
        id: bookmarksListView

        anchors.fill: parent

        model: ListModel {
            ListElement { section: "bookmarks" }
        }

        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: children.height

            sourceComponent: modelData == "bookmarks" ? bookmarksComponent : ""
        }

        section.property: "section"
        section.delegate: Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }

            height: sectionHeader.height + units.gu(1)
            color: bookmarksListBackground.color

            ListItem.Header {
                id: sectionHeader
                text: {
                    if (section == "bookmarks") {
                        return i18n.tr("Bookmarks")
                    }
                }
            }
        }

        section.labelPositioning: ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart
    }

    Component {
        id: bookmarksComponent

        BookmarksList {
            model: BookmarksChronologicalModel {
                sourceModel: bookmarksModel
            }

            footerLabelText: i18n.tr("see less")

            onBookmarkClicked: bookmarkRequested(url)
            onFooterLabelClicked: seeLessBookmarksRequested()
        }
    }
}
