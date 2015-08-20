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

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems
import webbrowserapp.private 0.1

FocusScope {
    id: historyViewWide

    property alias historyModel: historySearchModel.sourceModel
    property bool searchMode: false
    onSearchModeChanged: {
        if (searchMode) searchQuery.focus = true
        else {
            searchQuery.text = ""
            urlsListView.focus = true
        }
    }

    signal done()
    signal historyEntryClicked(url url)
    signal historyEntryRemoved(url url)
    signal newTabRequested()

    Keys.onLeftPressed: lastVisitDateListView.forceActiveFocus()
    Keys.onRightPressed: urlsListView.forceActiveFocus()
    Keys.onUpPressed: if (searchMode) searchQuery.focus = true
    Keys.onPressed: {
        if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_F) {
            searchMode = true
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            urlsListView.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
    }

    TextSearchFilterModel {
        id: historySearchModel
        searchFields: ["title", "url"]
        terms: searchQuery.terms
    }

    Row {
        id: historyViewWideRow
        anchors {
            top: topBar.bottom
            left: parent.left
            bottom: bottomToolbar.top
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }

        spacing: units.gu(1)

        Item {
            width: units.gu(40)
            height: parent.height

            ListView {
                id: lastVisitDateListView
                objectName: "lastVisitDateListView"

                anchors.fill: parent

                currentIndex: 0
                onCurrentIndexChanged: {
                    if (currentItem) {
                        historyLastVisitDateModel.setLastVisitDate(currentItem.lastVisitDate)
                    }
                    urlsListView.ViewItems.selectedIndices = []
                }

                model: HistoryLastVisitDateListModel {
                    sourceModel: historyLastVisitDateModel.sourceModel
                }

                delegate: ListItem {
                    objectName: "lastVisitDateDelegate"

                    property var lastVisitDate: model.lastVisitDate

                    anchors {
                        left: parent.left
                        right: parent.right
                        rightMargin: units.gu(1)
                    }

                    width: parent.width
                    height: units.gu(4)

                    color: lastVisitDateListView.currentIndex == index ? highlightColor : "transparent"

                    Label {
                        objectName: "lastVisitDateDelegateLabel"

                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: units.gu(1)
                            leftMargin: units.gu(2)
                        }

                        height: parent.height

                        text: {
                            if (!lastVisitDate.isValid()) {
                                return i18n.tr("All History")
                            }

                            var today = new Date()
                            today.setHours(0, 0, 0, 0)

                            var yesterday = new Date()
                            yesterday.setDate(yesterday.getDate() - 1)
                            yesterday.setHours(0, 0, 0, 0)

                            var entryDate = new Date(lastVisitDate)
                            entryDate.setHours(0, 0, 0, 0)

                            if (entryDate.getTime() == today.getTime()) {
                                return i18n.tr("Today")
                            } else if (entryDate.getTime() == yesterday.getTime()) {
                                return i18n.tr("Yesterday")
                            }
                            return Qt.formatDate(lastVisitDate, Qt.DefaultLocaleLongDate)
                        }

                        fontSize: "small"
                        color: lastVisitDateListView.currentIndex == index ? UbuntuColors.orange : UbuntuColors.darkGrey
                    }

                    onClicked: lastVisitDateListView.currentIndex = index
               }
            }

            Scrollbar {
                flickableItem: lastVisitDateListView
                align: Qt.AlignTrailing
            }
        }

        Item {
            width: historyViewWide.width - lastVisitDateListView.width - historyViewWideRow.spacing - units.gu(4)
            height: parent.height

            ListView {
                id: urlsListView
                objectName: "urlsListView"

                anchors.fill: parent

                Keys.onReturnPressed: historyEntrySelected()
                Keys.onEnterPressed: historyEntrySelected()

                model: HistoryLastVisitDateModel {
                    id: historyLastVisitDateModel
                    // Until a valid HistoryModel is assigned the TestSearchFilterModel
                    // will not report role names, and the HistoryLastVisit*Models will emit warnings
                    // since they need a dateLastVisit role to be present.
                    // We avoid this by assigning the sourceModel only when HistoryModel is ready.
                    sourceModel: historyModel ? historySearchModel : undefined
                }

                clip: true

                onModelChanged: urlsListView.currentIndex = -1

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        urlsListView.currentIndex = -1
                    } else {
                        urlsListView.currentIndex = 0
                    }
                }

                function historyEntrySelected() {
                    if (urlsListView.ViewItems.selectMode) {
                        currentItem.selected = !currentItem.selected
                    } else {
                        historyViewWide.historyEntryClicked(currentItem.url)
                    }
                }

                // Only use sections for "All History" history list
                section.property: historyLastVisitDateModel.lastVisitDate.isValid() ? "" : "lastVisitDate"
                section.delegate: HistorySectionDelegate {
                    width: parent.width - units.gu(3)
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(2)
                    todaySectionTitle: i18n.tr("Today")
                }

                delegate: UrlDelegate{
                    width: parent.width - units.gu(1)
                    height: units.gu(5)

                    color: urlsListView.currentIndex == index ? highlightColor : "transparent"

                    icon: model.icon
                    title: model.title ? model.title : model.url
                    url: model.url

                    headerComponent: Component {
                        Item {
                            height: units.gu(3)
                            width: timeLabel.width

                            Label {
                                id: timeLabel
                                anchors.centerIn: parent
                                text: Qt.formatTime(model.lastVisit)
                                fontSize: "xx-small"
                            }
                        }
                    }

                    onClicked: {
                        if (selectMode) {
                            selected = !selected
                        } else {
                            historyViewWide.historyEntryClicked(model.url)
                        }
                    }

                    onRemoved: {
                        if (urlsListView.count == 1) {
                            historyViewWide.historyEntryRemoved(model.url)
                            lastVisitDateListView.currentIndex = 0
                        } else {
                            historyViewWide.historyEntryRemoved(model.url)
                        }
                    }

                    onPressAndHold: {
                        if (historyViewWide.searchMode) historyViewWide.searchMode = false
                        selectMode = !selectMode
                        if (selectMode) {
                            urlsListView.ViewItems.selectedIndices = [index]
                        }
                    }
                }
            }

            Scrollbar {
                flickableItem: urlsListView
                align: Qt.AlignTrailing
            }
        }
    }

    Toolbar {
        id: topBar

        height: units.gu(7)

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        Label {
            visible: !urlsListView.ViewItems.selectMode &&
                     !historyViewWide.searchMode

            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(2)
                leftMargin: units.gu(2)
            }

            text: i18n.tr("History")
        }

        ToolbarAction {
            objectName: "backButton"

            visible: urlsListView.ViewItems.selectMode ||
                     historyViewWide.searchMode

            anchors {
                top: parent.top
                left: parent.left
                leftMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "back"
            text: i18n.tr("Cancel")

            onClicked: {
                if (historyViewWide.searchMode) {
                    historyViewWide.searchMode = false
                } else {
                    urlsListView.ViewItems.selectMode = false
                }
                lastVisitDateListView.forceActiveFocus()
            }
        }

        ToolbarAction {
            objectName: "selectButton"

            visible: urlsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: deleteButton.left
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "select"
            text: i18n.tr("Select all")

            onClicked: {
                if (urlsListView.ViewItems.selectedIndices.length === urlsListView.count) {
                    urlsListView.ViewItems.selectedIndices = []
                } else {
                    var indices = []
                    for (var i = 0; i < urlsListView.count; ++i) {
                        indices.push(i)
                    }
                    urlsListView.ViewItems.selectedIndices = indices
                }

                urlsListView.forceActiveFocus()
            }
        }

        ToolbarAction {
            id: deleteButton
            objectName: "deleteButton"

            visible: urlsListView.ViewItems.selectMode

            anchors {
                top: parent.top
                right: parent.right
                rightMargin: units.gu(2)
            }
            height: parent.height - units.gu(2)

            iconName: "delete"
            text: i18n.tr("Delete")
            enabled: urlsListView.ViewItems.selectedIndices.length > 0
            onClicked: {
                var indices = urlsListView.ViewItems.selectedIndices
                var urls = []
                for (var i in indices) {
                    urls.push(urlsListView.model.get(indices[i])["url"])
                }

                if (urlsListView.count == urls.length) {
                    lastVisitDateListView.currentIndex = 0
                }

                urlsListView.ViewItems.selectMode = false
                for (var j in urls) {
                    historyViewWide.historyEntryRemoved(urls[j])
                }

                lastVisitDateListView.forceActiveFocus()
            }
        }

        TextField {
            id: searchQuery
            objectName: "searchQuery"
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: units.gu(2)
            }
            width: units.gu(40)
            hasClearButton: true
            placeholderText: i18n.tr("search history")
            visible: historyViewWide.searchMode
            property var terms: text.split(/\s+/g).filter(function(term) { return term.length > 0 })

            Keys.onEscapePressed: historyViewWide.searchMode = false
            Keys.onDownPressed: urlsListView.focus = true
        }

        ToolbarAction {
            id: searchButton
            iconName: "search"
            objectName: "searchButton"
            visible: !urlsListView.ViewItems.selectMode &&
                     !historyViewWide.searchMode
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: units.gu(3.5)
            }
            height: parent.height - units.gu(2)
            onClicked: {
                historyViewWide.searchMode = true
                searchQuery.forceActiveFocus()
            }
        }

        ListItems.ThinDivider {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
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

            onClicked: historyViewWide.done()
        }

        ToolbarAction {
            objectName: "newTabButton"
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: {
                historyViewWide.newTabRequested()
                historyViewWide.done()
            }
        }
    }
}
