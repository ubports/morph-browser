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
import Ubuntu.Components.Extras.Browser 0.1

Item {
    id: timelineView

    property QtObject tabsModel
    property QtObject historyModel

    signal resetPositionRequested()
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

        model: ListModel {
            ListElement { timeframe: "today" }
            ListElement { timeframe: "yesterday" }
            ListElement { timeframe: "last7days" }
            ListElement { timeframe: "thismonth" }
            ListElement { timeframe: "thisyear" }
            ListElement { timeframe: "older" }
        }
        currentIndex: -1

        header: TabsList {
            width: parent.width
            height: units.gu(20)

            model: tabsModel

            onNewTabClicked: newTabRequested()
            onSwitchToTabClicked: switchToTabRequested(index)
            onTabRemoved: closeTabRequested(index)

            Connections {
                target: timelineView
                onResetPositionRequested: centerViewOnCurrentTab()
            }
        }

        delegate: Column {
            readonly property int timelineIndex: index

            visible: hostsView.count > 0
            height: visible ? header.height + hostsView.height + entriesView.height + spacing * (2 + (timeline.currentIndex >= 0)) : 0
            width: parent.width
            clip: true
            spacing: units.gu(2)

            TimelineHeader {
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

            ListView {
                id: hostsView

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                height: units.gu(12)

                spacing: units.gu(2)
                orientation: ListView.Horizontal

                model: HistoryHostListModel {
                    sourceModel: HistoryTimeframeModel {
                        sourceModel: historyModel
                        start: {
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
                            return date
                        }
                        end: {
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
                            return date
                        }
                    }
                }

                delegate: PageDelegate {
                    width: units.gu(12)
                    height: units.gu(12)
                    color: "white"

                    title: model.host ? model.host : i18n.tr("(local files)")

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if ((timeline.currentIndex == timelineIndex) &&
                                (entriesView.model == model.entries)) {
                                timeline.currentIndex = -1
                            } else {
                                timeline.currentIndex = timelineIndex
                                entriesView.model = model.entries
                            }
                        }
                    }
                }
            }

            ListView {
                id: entriesView

                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                height: 0
                clip: true

                spacing: units.gu(2)
                orientation: ListView.Horizontal

                delegate: PageDelegate {
                    width: units.gu(12)
                    height: units.gu(12)
                    color: "white"

                    title: model.title

                    MouseArea {
                        anchors.fill: parent
                        onClicked: historyEntryClicked(model.url)
                    }
                }

                states: [
                    State {
                        name: "expanded"
                        when: timelineIndex == timeline.currentIndex
                        PropertyChanges {
                            target: entriesView
                            height: units.gu(12)
                        }
                    }
                ]
                Behavior on height {
                    UbuntuNumberAnimation {}
                }
            }
        }
    }

    onResetPositionRequested: timeline.positionViewAtBeginning()
}
