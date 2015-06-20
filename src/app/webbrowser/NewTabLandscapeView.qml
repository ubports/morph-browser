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
import Qt.labs.settings 1.0
import Ubuntu.Components 1.2
import webbrowserapp.private 0.1
import ".."

Item {
    id: newTabViewLandscape

    property QtObject bookmarksModel
    property alias historyModel: historyTimeframeModel.sourceModel
    property Settings settingsObject
    property int selectedIndex: 0

    signal bookmarkClicked(url url)
    signal bookmarkRemoved(url url)
    signal historyEntryClicked(url url)

    TopSitesModel {
        id: topSitesModel
        sourceModel: HistoryTimeframeModel {
            id: historyTimeframeModel
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    Rectangle {
        id: sectionsRectangle
        height: units.gu(3)
        color: "#E8E8E8"

        clip: true

        anchors {
          left: parent.left
          right: parent.right
        }

        Row {
            id: sectionsRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: childrenRect.width

            anchors {
                top: parent.top
                bottom: parent.bottom
            }

            Repeater {
                id: sectionsRepeater
                model: [i18n.tr("Top sites"), i18n.tr("Bookmarks")]

                AbstractButton {
                    id: sectionButton
                    anchors {
                        top: parent ? parent.top : undefined
                        bottom: parent ? parent.bottom : undefined
                    }
                    width: label.width + units.gu(4)
                    height: sectionsRow.height + units.gu(2)
                    property bool selected: index === newTabViewLandscape.selectedIndex
                    onClicked: newTabViewLandscape.selectedIndex = index;

                    Label {
                        id: label
                        text: modelData
                        fontSize: "small"
                        anchors.centerIn: sectionButton
                        horizontalAlignment: Text.AlignHCenter
                        color: sectionButton.selected ? "#dd4814" : "#5d5d5d"
                    }

                    // vertical divider line
                    Rectangle {
                        id: verticalDividerLine
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                        }
                        height: units.dp(10)
                        width: units.dp(1)
                        visible: index === 0
                        color: "#5d5d5d"
                        opacity: 0.2
                    }
                }
            }
        }
    }

    Flickable {
        anchors {
            top: sectionsRectangle.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        contentHeight: contentColumn.height

        clip: true

        Column {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height

            Column {
                id: bookmarksColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }

                visible: newTabViewLandscape.selectedIndex === 1

                height: childrenRect.height
                spacing: 0

                UrlDelegate {
                    objectName: "homepageBookmark"
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: units.gu(5)

                    title: i18n.tr('Homepage')

                    leadingActions: null

                    url: newTabViewLandscape.settingsObject.homepage
                    onClicked: newTabViewLandscape.bookmarkClicked(url)
                }

                UrlsList {
                    objectName: "bookmarksList"
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    spacing: 0
                    limit: 10

                    model: newTabViewLandscape.bookmarksModel

                    onUrlClicked: newTabViewLandscape.bookmarkClicked(url)
                    onUrlRemoved: newTabViewLandscape.bookmarkRemoved(url)
                }
            }

            Label {
                objectName: "notopsites"

                height: units.gu(11)
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: topSitesModel.count == 0 && newTabViewLandscape.selectedIndex === 0

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: i18n.tr("You haven't visited any site yet")
                color: "#5d5d5d"
            }

            UrlsList {
                objectName: "topSitesList"
                anchors {
                    left: parent.left
                    right: parent.right
                }

                opacity: internal.seeMoreBookmarksView ? 0.0 : 1.0
                Behavior on opacity { UbuntuNumberAnimation {} }
                visible: newTabViewLandscape.selectedIndex === 0

                limit: 10
                spacing: 0

                model: topSitesModel

                onUrlClicked: newTabViewLandscape.historyEntryClicked(url)
                onUrlRemoved: newTabViewLandscape.historyModel.hide(url)
            }
        }
    }
}
