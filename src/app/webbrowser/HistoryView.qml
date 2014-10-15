/*
 * Copyright 2014 Canonical Ltd.
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
import webbrowserapp.private 0.1
import "upstreamcomponents"

Item {
    id: historyView

    property alias historyModel: historyTimeframeModel.sourceModel

    signal seeMoreEntriesClicked(var model)
    signal historyDomainRemoved(var domain)
    signal done()

    Rectangle {
        anchors.fill: parent
        color: "#f6f6f6"
    }

    Item {
        id: topBar
        visible: domainsListView.isInSelectionMode

        onVisibleChanged: visible ? topBarOpenAnimation.start() : topBarCloseAnimation.start()

        anchors { left: parent.left; right: parent.right; top: parent.top }

        Icon {
            name: "close"
            anchors {
                top: parent.top;
                bottom: parent.bottom;
                left: parent.left;
                margins: units.gu(1)
            }
            width: height
            MouseArea {
                anchors.fill: parent
                onClicked: domainsListView.cancelSelection()
            }
        }
        Icon {
            name: "select"
            anchors {
                top: parent.top;
                bottom: parent.bottom;
                right: deleteIcon.left;
                margins: units.gu(1)
            }
            width: height
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (domainsListView.selectedItems.count === domainsListView.count) {
                        domainsListView.clearSelection()
                    } else {
                        domainsListView.selectAll()
                    }
                }
            }
        }
        Icon {
            id: deleteIcon
            enabled: domainsListView.selectedItems.count > 0
            name: "delete"
            anchors {
                top: parent.top;
                bottom: parent.bottom;
                right: parent.right;
                margins: units.gu(1)
            }
            width: height
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    domainsListView.endSelection()
                }
            }
        }
    }

    UbuntuNumberAnimation {
        id: topBarOpenAnimation
        target: topBar
        property: "height"
        to: units.gu(5)
        alwaysRunToEnd: true
    }

    UbuntuNumberAnimation {
        id: topBarCloseAnimation
        target: topBar
        property: "height"
        to: 0
        alwaysRunToEnd: true
    }

    MultipleSelectionListView {
        id: domainsListView

        property var _currentSwipedItem: null

        anchors {
            top: topBar.bottom
            left: parent.left
            right: parent.right
            bottom: toolbar.top
            margins: units.gu(2)
        }

        listModel: HistoryDomainListChronologicalModel {
            sourceModel: HistoryDomainListModel {
                sourceModel: HistoryTimeframeModel {
                    id: historyTimeframeModel
                }
            }
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width
        }

        onSelectionDone: {
            var domains = new Array();
            for (var i=0; i < items.count; i++) {
                domains[i] = items.get(i).model.domain
            }
            for (var i=0; i < domains.length; i++) {
                historyView.historyDomainRemoved(domains[i])
            }
        }

        listDelegate: UrlDelegate {
            id: urlDelegate
            width: parent.width
            height: units.gu(5)

            title: model.domain
            url: lastVisitedTitle
            icon: model.lastVisitedIcon

            property var removalAnimation
            function remove() {
                removalAnimation.start()
            }

            selectionMode: domainsListView.isInSelectionMode
            selected: domainsListView.isSelected(urlDelegate)

            onSwippingChanged: {
                domainsListView._updateSwipeState(urlDelegate)
            }

            onSwipeStateChanged: {
                domainsListView._updateSwipeState(urlDelegate)
            }

            leftSideAction: Action {
                iconName: "delete"
                text: i18n.tr("Delete")
                onTriggered: {
                    urlDelegate.remove()
                }
            }

            ListView.onRemove: ScriptAction {
                script: {
                    if (domainsListView._currentSwipedItem === urlDelegate) {
                        domainsListView._currentSwipedItem = null
                    }
                }
            }

            removalAnimation: SequentialAnimation {
                alwaysRunToEnd: true

                PropertyAction {
                    target: urlDelegate
                    property: "ListView.delayRemove"
                    value: true
                }

                UbuntuNumberAnimation {
                    target: urlDelegate
                    property: "height"
                    to: 0
                }

                PropertyAction {
                    target: urlDelegate
                    property: "ListView.delayRemove"
                    value: false
                }

                ScriptAction {
                    script: {
                        historyView.historyDomainRemoved(model.domain)
                    }
                }
            }

            onItemClicked: {
                if (domainsListView.isInSelectionMode) {
                    if (!domainsListView.selectItem(urlDelegate)) {
                        domainsListView.deselectItem(urlDelegate)
                    }
                }
                else {
                    historyView.seeMoreEntriesClicked(model.entries)
                }
            }
            onItemPressAndHold: domainsListView.startSelection()
        }

        /*
         * Functions for manage swype and multiple selection together
         * Developed upstream
         */
        function _updateSwipeState(item) {
            if (item.swipping) {
                return
            }

            if (item.swipeState !== "Normal") {
                if (domainsListView._currentSwipedItem !== item) {
                    if (domainsListView._currentSwipedItem) {
                        domainsListView._currentSwipedItem.resetSwipe()
                    }
                    domainsListView._currentSwipedItem = item
                }
            } else if (item.swipeState !== "Normal"
            && domainsListView._currentSwipedItem === item) {
                domainsListView._currentSwipedItem = null
            }
        }
    }

    Toolbar {
        id: toolbar
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

            color: "white"

            text: i18n.tr("Done")

            onClicked: historyView.done()
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
                historyView.done()
            }
        }
    }
}
