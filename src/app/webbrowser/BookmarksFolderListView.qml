/*
 * Copyright 2015 Canonical Ltd.
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

Item {
    id: bookmarksFolderListViewItem

    property alias model: bookmarksFolderListModel.sourceModel 

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)

    height: bookmarksFolderListView.contentHeight

    BookmarksFolderListModel {
        id: bookmarksFolderListModel
    }

    Component {
        id: bookmarksFolderDelegate

        Column {
            id: bookmarksFolderColumn

            property bool expanded: true

            anchors {
                left: parent.left
                right: parent.right
            }
 
            Item {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                }
 
                width: parent.width - units.gu(2)
                height: units.gu(6.5)

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: units.gu(2.5)
                    }

                    height: units.gu(2)

                    text: {
                        var ret
                        if (bookmarksFolderColumn.expanded) {
                            ret = "- "
                        } else {
                            ret = "+ "
                        }

                        if (folder) {
                            return ret + folder
                        } else {
                            return ret + i18n.tr("All Bookmarks")
                        }
                    }

                    fontSize: "small"
                    color: UbuntuColors.darkGrey
                }

                ListItem.ThinDivider {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: units.gu(1)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: bookmarksFolderColumn.expanded = !bookmarksFolderColumn.expanded
                }
            }

            Loader {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                visible: status == Loader.Ready

                active: bookmarksFolderColumn.expanded
                sourceComponent: UrlsList {
                    spacing: 0

                    model: entries

                    onUrlClicked: bookmarksFolderListViewItem.bookmarkClicked(url)
                    onUrlRemoved: bookmarksFolderListViewItem.bookmarkRemoved(url)
                }
            }
        }
    }

    ListView {
        id: bookmarksFolderListView
        anchors.fill: parent
        interactive: false

        model: bookmarksFolderListModel
        delegate: bookmarksFolderDelegate
    }
}
