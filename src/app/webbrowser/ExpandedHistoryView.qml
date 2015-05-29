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
import ".."

Item {
    id: expandedHistoryView

    property alias model: entriesListView.model

    signal historyEntryClicked(url url)
    signal historyEntryRemoved(url url)
    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    ListView {
        id: entriesListView

        property var _currentSwipedItem: null

        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width
        }

        delegate: UrlDelegate {
            id: entriesDelegate
            objectName: "entriesDelegate"
            width: parent.width
            height: units.gu(5)

            url: model.url
            title: model.title
            icon: model.icon

            property var removalAnimation
            function remove() {
                removalAnimation.start()
            }

            onSwippingChanged: {
                entriesListView._updateSwipeState(entriesDelegate)
            }

            onSwipeStateChanged: {
                entriesListView._updateSwipeState(entriesDelegate)
            }

            leftSideAction: Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered: {
                    entriesDelegate.remove()
                }
            }

            ListView.onRemove: ScriptAction {
                script: {
                    if (entriesListView._currentSwipedItem === entriesDelegate) {
                        entriesListView._currentSwipedItem = null
                    }
                }
            }

            removalAnimation: SequentialAnimation {
                alwaysRunToEnd: true

                PropertyAction {
                    target: entriesDelegate
                    property: "ListView.delayRemove"
                    value: true
                }

                UbuntuNumberAnimation {
                    target: entriesDelegate
                    property: "height"
                    to: 0
                }

                PropertyAction {
                    target: entriesDelegate
                    property: "ListView.delayRemove"
                    value: false
                }

                ScriptAction {
                    script: {
                        if(entriesListView.count === 1) {
                            expandedHistoryView.done()
                        }
                        historyEntryRemoved(model.url)
                    }
                }
            }

            onItemClicked: {
                historyEntryClicked(model.url)
            }
        }

        function _updateSwipeState(item) {
            if (item.swipping) {
                return
            }

            if (item.swipeState !== "Normal") {
                if (entriesListView._currentSwipedItem !== item) {
                    if (entriesListView._currentSwipedItem) {
                        entriesListView._currentSwipedItem.resetSwipe()
                    }
                    entriesListView._currentSwipedItem = item
                }
            } else if (item.swipeState !== "Normal"
            && entriesListView._currentSwipedItem === item) {
                entriesListView._currentSwipedItem = null
            }
        }
    }

    Rectangle {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: units.gu(8)

        color: "#f6f6f6"

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: units.dp(1)
            color: "#dedede"
        }

        UrlDelegate {
            anchors {
                left: parent.left
                right: doneButton.left
                rightMargin: units.gu(1)
                top: parent.top
                topMargin: -units.gu(0.7)
            }
            icon: expandedHistoryView.model.lastVisitedIcon
            title: expandedHistoryView.model.domain
            url: i18n.tr("%1 page", "%1 pages", entriesListView.count).arg(entriesListView.count)
        }

        Button {
            id: doneButton

            strokeColor: UbuntuColors.darkGrey

            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            text: i18n.tr("Less")

            onClicked: expandedHistoryView.done()
        }
    }
}
