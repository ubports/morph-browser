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

    ListView {
        id: bookmarksFolderListView
        anchors.fill: parent
        interactive: false

        model: bookmarksFolderListModel
        delegate: Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
 
            height: active ? delegate.height : 0
            active: entries.count > 0

            sourceComponent: Component {
                id: delegate

                Column {
                    id: delegateColumn
                    objectName: "bookmarkFolderDelegate_" + folder
        
                    property bool expanded: true
        
                    anchors {
                        left: parent ? parent.left : undefined 
                        right: parent ? parent.right : undefined
                    }
         
                    Item {
                        anchors {
                            left: parent.left
                            leftMargin: units.gu(2)
                        }
         
                        width: parent.width - units.gu(2)
                        height: units.gu(6.5)

                        Row {
                            anchors {
                                left: parent.left
                                leftMargin: units.gu(1.5)
                                right: parent.right
                            }

                            height: units.gu(6)
                            spacing: units.gu(1.5)

                            Icon {
                                id: expandedIcon
                                name: delegateColumn.expanded ? "go-down" : "go-next"

                                height: units.gu(2)
                                width: height

                                anchors {
                                    leftMargin: units.gu(1)
                                    topMargin: units.gu(2)
                                    top: parent.top
                                }
                            }

                            Label {
                                width: parent.width - expandedIcon.width - units.gu(3)
                                anchors.verticalCenter: expandedIcon.verticalCenter

                                text: folder ? folder : i18n.tr("All Bookmarks")
                                fontSize: "small"
                            }
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
                            onClicked: delegateColumn.expanded = !delegateColumn.expanded
                        }
                    }
        
                    Loader {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
        
                        visible: status == Loader.Ready
        
                        active: delegateColumn.expanded
                        sourceComponent: UrlsList {
                            spacing: 0
        
                            model: entries
        
                            onUrlClicked: bookmarksFolderListViewItem.bookmarkClicked(url)
                            onUrlRemoved: bookmarksFolderListViewItem.bookmarkRemoved(url)
                        }
                    }
                }
            }
        }
    }
}
