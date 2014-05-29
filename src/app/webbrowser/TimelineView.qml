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
import webbrowserapp.private 0.1

Item {
    id: timelineView

    property QtObject tabsModel
    property QtObject historyModel
    property QtObject bookmarksModel

    signal newTabRequested()
    signal switchToTabRequested(int index)
    signal closeTabRequested(int index)
    signal historyEntryClicked(url url)

    Rectangle {
        anchors.fill: parent
        color: "#EEEEEE"
    }

    ListView {
        id: timeline

        anchors.fill: parent
        verticalLayoutDirection: ListView.BottomToTop
        clip: true
        interactive: loaded
        boundsBehavior: Flickable.StopAtBounds

        model: ListModel {}
        currentIndex: -1

        readonly property var timeframes: ["today", "yesterday", "last7days", "thismonth", "thisyear", "older"]
        readonly property bool loaded: model.count == timeframes.length
        Timer {
            interval: 1
            repeat: true
            running: !timeline.loaded
            onTriggered: timeline.model.append({ timeframe: timeline.timeframes[timeline.model.count] })
        }

        header: TabsList {
            width: parent.width
            height: units.gu(24)

            tabsModel: timelineView.tabsModel
            bookmarksModel: timelineView.bookmarksModel

            onNewTabClicked: newTabRequested()
            onSwitchToTabClicked: switchToTabRequested(index)
            onTabRemoved: closeTabRequested(index)
        }

        delegate: Column {
            readonly property int timelineIndex: index

            visible: domainsView.count > 0
            height: visible ? header.height + domainsView.height + entriesView.height + spacing * (2 + (timeline.currentIndex >= 0)) : 0
            width: parent.width
            clip: true
            spacing: units.gu(2)

            ListItem.Header {
                id: header
                text: {
                    if (model.timeframe == "today") {
                        return i18n.tr("Today")
                    } else if (model.timeframe == "yesterday") {
                        return i18n.tr("Yesterday")
                    } else if (model.timeframe == "last7days") {
                        return i18n.tr("Last 7 Days")
                    } else if (model.timeframe == "thismonth") {
                        return i18n.tr("This Month")
                    } else if (model.timeframe == "thisyear") {
                        return i18n.tr("This Year")
                    } else if (model.timeframe == "older") {
                        return i18n.tr("Older")
                    }
                }
            }

            Item {
                id: entriesView

                property var model
                property string domain: ""

                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: 0
                opacity: 0.0
                visible: opacity > 0

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.1
                }

                Image {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    fillMode: Image.TileHorizontally
                    source: "assets/expanded_top_innershadow.png"
                }

                Image {
                    id: arrow
                    anchors.top: parent.bottom
                    x: domainsView.currentItem ? domainsView.currentItem.x + (domainsView.currentItem.width + width) / 2 - domainsView.contentX : 0
                    source: "assets/expanded_tooltip.png"
                }

                Image {
                    anchors {
                        top: parent.bottom
                        left: parent.left
                        right: arrow.left
                    }
                    fillMode: Image.TileHorizontally
                    source: "assets/expanded_bottom_highlight.png"
                }

                Image {
                    anchors {
                        top: parent.bottom
                        left: arrow.right
                        right: parent.right
                    }
                    fillMode: Image.TileHorizontally
                    source: "assets/expanded_bottom_highlight.png"
                }

                ListView {
                    id: entriesListView

                    anchors {
                        fill: parent
                        margins: units.gu(2)
                        topMargin: units.gu(1.5)
                    }

                    spacing: units.gu(2)
                    orientation: ListView.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: entriesView.model

                    delegate: PageDelegate {
                        width: units.gu(12)
                        height: units.gu(15)

                        url: model.url
                        label: model.title ? model.title : model.url

                        //property url thumbnailSource: "image://webthumbnail/" + model.url
                        //thumbnail: WebThumbnailer.thumbnailExists(model.url) ? thumbnailSource : ""

                        canBookmark: true
                        bookmarksModel: timelineView.bookmarksModel

                        onClicked: historyEntryClicked(model.url)
                    }
                }

                states: State {
                    name: "expanded"
                    when: timelineIndex == timeline.currentIndex
                    PropertyChanges {
                        target: entriesView
                        height: units.gu(19)
                        opacity: 1.0
                    }
                }

                transitions: Transition {
                    SequentialAnimation {
                        UbuntuNumberAnimation { properties: "height,opacity" }
                        ScriptAction {
                            // XXX: This action is instantaneous, the view jumps to the index
                            // without animating contentY. Unfortunately, manipulating contentY
                            // to position the view at a given index is unreliable and discouraged
                            // (see http://qt-project.org/doc/qt-5.0/qtquick/qml-qtquick2-listview.html#positionViewAtIndex-method).
                            script: timeline.positionViewAtIndex(timelineIndex, ListView.Center)
                        }
                    }
                }
            }

            ListView {
                id: domainsView

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                height: units.gu(15)

                spacing: units.gu(2)
                orientation: ListView.Horizontal
                boundsBehavior: Flickable.StopAtBounds

                model: HistoryDomainListChronologicalModel {
                    sourceModel: HistoryDomainListModel {
                        sourceModel: HistoryTimeframeModel {
                            function setStart() {
                                var date = new Date()
                                if (model.timeframe == "yesterday") {
                                    date.setDate(date.getDate() - 1)
                                } else if (model.timeframe == "last7days") {
                                    date.setDate(date.getDate() - 7)
                                } else if (model.timeframe == "thismonth") {
                                    date.setDate(1)
                                } else if (model.timeframe == "thisyear") {
                                    date.setMonth(0)
                                    date.setDate(1)
                                } else if (model.timeframe == "older") {
                                    date.setFullYear(0, 0, 1)
                                }
                                date.setHours(0)
                                date.setMinutes(0)
                                date.setSeconds(0)
                                date.setMilliseconds(0)
                                start = date
                            }
                            function setEnd() {
                                var date = new Date()
                                if (model.timeframe == "yesterday") {
                                    date.setDate(date.getDate() - 1)
                                } else if (model.timeframe == "last7days") {
                                    date.setDate(date.getDate() - 2)
                                } else if (model.timeframe == "thismonth") {
                                    date.setDate(date.getDate() - 8)
                                } else if (model.timeframe == "thisyear") {
                                    date.setDate(0)
                                } else if (model.timeframe == "older") {
                                    date.setMonth(0)
                                    date.setDate(0)
                                }
                                date.setHours(23)
                                date.setMinutes(59)
                                date.setSeconds(59)
                                date.setMilliseconds(999)
                                end = date
                            }
                            Component.onCompleted: {
                                setStart()
                                setEnd()
                                sourceModel = historyModel
                            }
                        }
                    }
                }

                delegate: PageDelegate {
                    width: units.gu(12)
                    height: units.gu(15)

                    label: {
                        if (model.domain === "(local)") {
                            return i18n.tr("(local files)")
                        } else if (model.domain === "(none)") {
                            return i18n.tr("(other)")
                        } else {
                            return model.domain
                        }
                    }

                    //property url thumbnailSource: "image://webthumbnail/" + model.domain
                    //thumbnail: WebThumbnailer.thumbnailExists(model.domain) ? thumbnailSource : ""

                    onClicked: {
                        if ((timeline.currentIndex == timelineIndex) &&
                            (entriesView.domain === model.domain)) {
                            domainsView.currentIndex = -1
                            timeline.currentIndex = -1
                        } else {
                            domainsView.currentIndex = index
                            timeline.currentIndex = timelineIndex
                            entriesView.domain = model.domain
                            entriesView.model = model.entries
                        }
                    }
                }
            }
        }

        ActivityIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            y: timeline.height - timeline.contentHeight - units.gu(8)
            visible: y > 0
            running: !timeline.loaded
        }
    }

    onVisibleChanged: {
        if (visible) {
            timeline.positionViewAtBeginning()
            // Ensure that the header (currently viewing) is fully visible
            timeline.contentY += timeline.headerItem.height
            timeline.headerItem.centerViewOnCurrentTab()
        } else {
            timeline.currentIndex = -1
        }
    }
}
