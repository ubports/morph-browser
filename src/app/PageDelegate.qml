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
    property alias bookmarked: bookmarker.checked
    property QtObject bookmarksModel

    signal clicked()

    onBookmarkedChanged: {
        var previouslyBookmarked = bookmarksModel.contains(pageDelegate.url)
        if (bookmarked && !previouslyBookmarked) {
            bookmarksModel.add(pageDelegate.url, pageDelegate.label, "")
        } else if (!bookmarked && previouslyBookmarked) {
            bookmarksModel.remove(pageDelegate.url)
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

        Label {
            id: label
            width: parent.width
            height: units.gu(1)
            fontSize: "small"
            elide: Text.ElideRight
        }
    }

    states: State {
        name: "close"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: pageDelegate.clicked()
        onPressAndHold: {
            if (pageDelegate.canClose) {
                pageDelegate.state = (pageDelegate.state === "" ? "close" : "")
            }
        }
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

    // Temporary placeholder until design provides assets
    CheckBox {
        id: bookmarker

        visible: pageDelegate.canBookmark

        anchors {
            top: parent.top
            right: parent.right
        }
    }
    onBookmarksModelChanged: {
        if (bookmarksModel) {
            bookmarked = bookmarksModel.contains(url)
        }
    }
}
