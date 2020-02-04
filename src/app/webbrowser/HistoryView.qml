/*
 * Copyright 2014-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1
import ".." as Common
import "." as Local

Common.BrowserPage {
    id: historyView

    signal seeMoreEntriesClicked(var model)
    signal newTabRequested()

    title: domainsListView.ViewItems.selectMode ? "" : i18n.tr("History")

    showBackAction: !domainsListView.ViewItems.selectMode
    leadingActions: [closeAction]
    trailingActions: domainsListView.ViewItems.selectMode ? [selectAllAction, deleteAction] : []

    Timer {
        // Set the model asynchronously to ensure
        // the view is displayed as early as possible.
        id: loadModelTimer
        interval: 1
        onTriggered: historyDomainListModel.sourceModel = HistoryModel
    }

    function loadModel() { loadModelTimer.restart() }

    ListView {
        id: domainsListView
        objectName: "domainsListView"

        focus: true
        currentIndex: 0

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: toolbar.top
        }

        model: HistoryDomainListModel {
            id: historyDomainListModel
        }

        section.property: "lastVisitDate"
        section.delegate: HistorySectionDelegate {
            width: parent.width - units.gu(2)
            anchors.left: parent.left
            anchors.leftMargin: units.gu(2)
        }

        delegate: UrlDelegate {
            id: urlDelegate
            objectName: "historyViewDomainDelegate"
            width: parent.width
            height: units.gu(5)

            readonly property int modelIndex: index

            title: model.domain
            url: lastVisitedTitle
            icon: model.lastVisitedIcon

            onClicked: {
                if (selectMode) {
                    selected = !selected
                } else {
                    historyView.seeMoreEntriesClicked(model.entries)
                }
            }
            onRemoved: HistoryModel.removeEntriesByDomain(model.domain)
            onPressAndHold: {
                selectMode = !selectMode
                if (selectMode) {
                    domainsListView.ViewItems.selectedIndices = [index]
                }
            }
        }

        Keys.onDeletePressed: currentItem.removed()
    }

    Local.Toolbar {
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

            strokeColor: theme.palette.normal.baseText

            text: i18n.tr("Done")

            onClicked: historyView.back()
        }

        ToolbarAction {
            objectName: "newTabAction"
            anchors {
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - units.gu(2)

            text: i18n.tr("New tab")
            iconName: "tab-new"

            onClicked: {
                historyView.newTabRequested()
                historyView.back()
            }
        }
    }

    Action {
        id: closeAction
        objectName: "close"
        iconName: "close"
        onTriggered: domainsListView.ViewItems.selectMode = false
    }

    Action {
        id: selectAllAction
        objectName: "selectAll"
        iconName: "select"
        onTriggered: {
            if (domainsListView.ViewItems.selectedIndices.length === domainsListView.count) {
                domainsListView.ViewItems.selectedIndices = []
            } else {
                var indices = []
                for (var i = 0; i < domainsListView.count; ++i) {
                    indices.push(i)
                }
                domainsListView.ViewItems.selectedIndices = indices
            }
        }
    }

    Action {
        id: deleteAction
        objectName: "delete"
        iconName: "delete"
        enabled: domainsListView.ViewItems.selectedIndices.length > 0
        onTriggered: {
            var indices = domainsListView.ViewItems.selectedIndices
            var domains = []
            for (var i in indices) {
                domains.push(domainsListView.model.get(indices[i]).domain)
            }
            domainsListView.ViewItems.selectMode = false
            for (var j in domains) {
                HistoryModel.removeEntriesByDomain(domains[j])
            }
        }
    }
}
