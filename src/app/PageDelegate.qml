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

Item {
    id: pageDelegate

    property url url
    property alias thumbnail: thumbnail.source
    property alias label: label.text
    property bool canClose: false
    property bool canBookmark: false
    property bool bookmarked
    property QtObject bookmarksModel

    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: pageDelegate.clicked()
        onPressAndHold: {
            if (pageDelegate.canClose) {
                pageDelegate.state = (pageDelegate.state === "" ? "close" : "")
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: units.gu(1)

        UbuntuShape {
            width: parent.width
            height: width

            image: Image {
                id: thumbnail
            }
        }

        MouseArea {
            width: parent.width
            height: units.gu(3)

            Row {
                anchors.fill: parent
                spacing: units.gu(1)

                Image {
                    id: starIcon
                    source: pageDelegate.bookmarked ? "assets/browser_favourite_on.png"
                                                    : "assets/browser_favourite_off.png"
                    visible: pageDelegate.canBookmark
                    width: visible ? units.gu(2) : 0
                    height: units.gu(2)
                }

                Label {
                    id: label
                    fontSize: "small"
                    width: parent.width - starIcon.width - (starIcon.visible ? parent.spacing : 0)
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }

            enabled: pageDelegate.canBookmark
            onClicked: pageDelegate.bookmarked = !pageDelegate.bookmarked
        }
    }

    states: State {
        name: "close"
    }

    Item {
        width: units.gu(5)
        height: units.gu(5)
        anchors {
            top: parent.top
            topMargin: -units.gu(1)
            right: parent.right
            rightMargin: -units.gu(1)
        }

        Image {
            id: closeButton

            source: "assets/close_btn.png"

            anchors.centerIn: parent
            width: units.gu(4)
            height: units.gu(4)

            states: State {
                name: "hidden"
                PropertyChanges {
                    target: closeButton
                    width: 0
                    height: 0
                }
            }
            state: (pageDelegate.state === "close") ? "" : "hidden"

            transitions: Transition {
                UbuntuNumberAnimation {
                    properties: "width,height"
                }
            }
        }
    }

    onBookmarksModelChanged: {
        if (bookmarksModel) {
            bookmarked = bookmarksModel.contains(url)
        }
    }

    onBookmarkedChanged: {
        var previouslyBookmarked = bookmarksModel.contains(pageDelegate.url)
        if (bookmarked && !previouslyBookmarked) {
            bookmarksModel.add(pageDelegate.url, pageDelegate.label, "")
        } else if (!bookmarked && previouslyBookmarked) {
            bookmarksModel.remove(pageDelegate.url)
        }
    }

    Connections {
        target: bookmarksModel
        onAdded: if (url === pageDelegate.url) bookmarked = true
        onRemoved: if (url === pageDelegate.url) bookmarked = false
    }
}
