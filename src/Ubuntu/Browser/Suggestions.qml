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
import Ubuntu.Components.ListItems 0.1 as ListItem

Rectangle {
    id: suggestions

    property alias count: listview.count
    property alias contentHeight: listview.contentHeight

    signal selected(url url)

    radius: units.gu(0.5)
    color: "white"
    border {
        color: "#c8c8c8"
        width: 1
    }

    clip: true

    ListView {
        id: listview

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: parent.height

        model: historyMatches

        delegate: ListItem.Base {
            // Not using ListItem.Subtitled because it’s not themable,
            // and we want the subText to be on one line only.

            property alias text: label.text
            property alias subText: subLabel.text

            __height: Math.max(middleVisuals.height, units.gu(6))

            Item  {
                id: middleVisuals
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: childrenRect.height + label.anchors.topMargin + subLabel.anchors.bottomMargin

                Label {
                    id: label
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    elide: Text.ElideRight
                    text: highlightTerms(title, historyMatches.terms)
                }

                Label {
                    id: subLabel
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: label.bottom
                    }
                    fontSize: "small"
                    elide: Text.ElideRight
                    text: highlightTerms(url, historyMatches.terms)
                }
            }

            onClicked: suggestions.selected(url)

            function highlightTerms(text, terms) {
                if (text === undefined) {
                    return ''
                }
                var highlighted = text.toString()
                var count = terms.length
                for (var i = 0; i < count; ++i) {
                    var term = terms[i]
                    highlighted = highlighted.replace(new RegExp(term, 'ig'), '<b>$&</b>')
                }
                highlighted = highlighted.replace(new RegExp('&', 'g'), '&amp;')
                return highlighted
            }
        }
    }

    Scrollbar {
        flickableItem: listview
        align: Qt.AlignTrailing
    }
}
