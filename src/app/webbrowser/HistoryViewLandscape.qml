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
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItems
import webbrowserapp.private 0.1

Item {
    id: historyViewLandscape

    property alias historyModel: historyTimeframeModel.sourceModel
    property alias count: lastVisitDateListView.count

    signal historyEntryClicked(url url)
    signal historyEntryRemoved(url url)
    signal done()

    Rectangle {
        anchors.fill: parent
    }

    Row {
        anchors {
            top: lastVisitedHeader.bottom
            left: parent.left
            bottom: bottomToolbar.top
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        spacing: units.gu(2)

        ListView {
            id: lastVisitDateListView

            property int selectedIndex: -1

            width: units.gu(40)
            height: parent.height

            model: HistoryLastVisitDateListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }

            delegate: ListItem {
                anchors {
                    left: parent.left
                    right: parent.right
                }

                width: parent.width
                height: units.gu(4)

                Label {
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: units.gu(1)
                        leftMargin: units.gu(2)
                    }

                    height: parent.height

                    text: {
                        var today = new Date()
                        today.setHours(0, 0, 0, 0)

                        var yesterday = new Date()
                        yesterday.setDate(yesterday.getDate() - 1)
                        yesterday.setHours(0, 0, 0, 0)

                        var entryDate = new Date()
                        entryDate.setDate(lastVisitDate.getDate())
                        entryDate.setHours(0, 0, 0, 0)
                         
                        if (entryDate.getTime() == today.getTime()) {
                            return i18n.tr("Today")
                        } else if (entryDate.getTime() == yesterday.getTime()) {
                            return i18n.tr("Yesterday")
                        }
                        return Qt.formatDate(lastVisitDate, Qt.DefaultLocaleLongDate)
                    }

                    fontSize: "small"
                    font.bold: lastVisitDateListView.selectedIndex == index
                }

                onClicked: {
                    lastVisitDateListView.selectedIndex = index
                    urlsListView.model = entries
                }
            }
        }

        ListView {
            id: urlsListView
            width: historyViewLandscape.width - lastVisitDateListView.width
            height: parent.height

            model: historyViewLandscape.historyModel

            delegate: Row {
                width: parent.width
                height: units.gu(5)

                spacing: units.gu(1)

                Item {
                    height: parent.height
                    width: timeLabel.width
                
                    Label {
                        id: timeLabel
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(model.lastVisit, "hh:mm")
                        fontSize: "xx-small"
                    }
                }

                Item {
                    width: parent.width - timeLabel.width - units.gu(1)
                    height: parent.height
 
                    UrlDelegate{
                        anchors.fill: parent
   
                        icon: model.icon
                        title: model.title ? model.title : model.url
                        url: model.url

                        onClicked: historyViewLandscape.historyEntryClicked(model.url)
                        onRemoved: {
                            if (urlsListView.count == 1) {
                                historyViewLandscape.historyEntryRemoved(model.url)
                                lastVisitDateListView.selectedIndex = -1
                                urlsListView.model = historyViewLandscape.historyModel
                            } else {
                                historyViewLandscape.historyEntryRemoved(model.url)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: lastVisitedHeader

        width: parent.width
        height: units.gu(7)

        Label {
            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(2)
                leftMargin: units.gu(2)
            }

            text: i18n.tr("Last Visited")    
        }

        ListItems.ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: units.gu(1)
            }
        }
    }

    Toolbar {
        id: bottomToolbar
        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Button {
            objectName: "doneButton"
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }

            strokeColor: UbuntuColors.darkGrey

            text: i18n.tr("Done")

            onClicked: historyViewLandscape.done()
        }

        ToolbarAction {
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: {
                browser.openUrlInNewTab("", true)
                historyViewLandscape.done()
            }
        }
    }
}
