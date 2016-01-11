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
import QtTest 1.0
import "../../../src/app/webbrowser"
import webbrowserapp.private 0.1

Item {
    id: root

    width: 300
    height: 500

    readonly property var historyView: historyViewLoader.item

    Loader {
        id: historyViewLoader
        anchors.fill: parent
        active: false
        focus: true
        sourceComponent: HistoryView {
            focus: true
        }
    }

    SignalSpy {
        id: seeMoreEntriesClickedSpy
        target: historyView
        signalName: "seeMoreEntriesClicked"
    }

    SignalSpy {
        id: newTabRequestedSpy
        target: historyView
        signalName: "newTabRequested"
    }

    SignalSpy {
        id: doneSpy
        target: historyView
        signalName: "done"
    }

    WebbrowserTestCase {
        name: "HistoryView"
        when: windowShown

        function init() {
            HistoryModel.databasePath = ":memory:"
            populate()
            historyViewLoader.active = true
            waitForRendering(historyView)
            historyView.loadModel()
            var domainsList = findChild(historyView, "domainsListView")
            waitForRendering(domainsList)
            tryCompare(domainsList, "count", 3)
            compare(seeMoreEntriesClickedSpy.count, 0)
            compare(doneSpy.count, 0)
        }

        function populate() {
            HistoryModel.add("http://example.com/foo", "foo", "")
            HistoryModel.add("http://example.org/bar", "bar", "")
            HistoryModel.add("http://example.net/baz", "baz", "")
            compare(HistoryModel.count, 3)
        }

        function cleanup() {
            HistoryModel.databasePath = ""
            seeMoreEntriesClickedSpy.clear()
            doneSpy.clear()
        }

        function test_done() {
            var button = findChild(historyView, "doneButton")
            clickItem(button)
            compare(doneSpy.count, 1)
        }

        function test_new_tab() {
            var action = findChild(historyView, "newTabAction")
            clickItem(action)
            compare(newTabRequestedSpy.count, 1)
            compare(doneSpy.count, 1)
        }

        function test_see_more_entries() {
            var listview = findChild(historyView, "domainsListView")
            var domain = getListItems(listview, "historyViewDomainDelegate")[0]
            clickItem(domain)
            compare(seeMoreEntriesClickedSpy.count, 1)
            compare(seeMoreEntriesClickedSpy.signalArguments[0][0].domain, domain.title)
        }

        function test_delete_domain() {
            var listview = findChild(historyView, "domainsListView")
            var domain = getListItems(listview, "historyViewDomainDelegate")[1]
            swipeToDeleteAndConfirm(domain)
            tryCompare(HistoryModel, "count", 2)
        }

        function test_exit_select_mode() {
            var listview = findChild(historyView, "domainsListView")
            var domains = getListItems(listview, "historyViewDomainDelegate")
            var first = domains[0]
            verify(!first.selectMode)

            longPressItem(first)
            tryCompare(first, "selectMode", true)

            var closeButton = findChild(historyView, "closeButton")
            clickItem(closeButton)
            tryCompare(first, "selectMode", false)
        }

        function test_delete_multiple_domains() {
            var listview = findChild(historyView, "domainsListView")
            var domains = getListItems(listview, "historyViewDomainDelegate")
            var first = domains[0]
            verify(!first.selectMode)

            longPressItem(first)
            tryCompare(first, "selectMode", true)
            tryCompare(first, "selected", true)
            var third = domains[2]
            verify(!third.selected)

            clickItem(third)
            tryCompare(third, "selected", true)

            var deleteButton = findChild(historyView, "deleteButton")
            clickItem(deleteButton)
            tryCompare(first, "selectMode", false)
            tryCompare(HistoryModel, "count", 1)
        }

        function test_select_all() {
            var listview = findChild(historyView, "domainsListView")
            var domains = getListItems(listview, "historyViewDomainDelegate")
            var first = domains[0], second = domains[1], third = domains[2]
            verify(!first.selectMode)

            longPressItem(first)
            tryCompare(first, "selectMode", true)
            tryCompare(first, "selected", true)
            verify(!second.selected)
            verify(!third.selected)
            var deleteButton = findChild(historyView, "deleteButton")
            verify(deleteButton.enabled)

            var selectAllButton = findChild(historyView, "selectAllButton")
            clickItem(selectAllButton)
            verify(first.selected)
            tryCompare(second, "selected", true)
            tryCompare(third, "selected", true)

            clickItem(selectAllButton)
            tryCompare(first, "selected", false)
            tryCompare(second, "selected", false)
            tryCompare(third, "selected", false)
            verify(!deleteButton.enabled)

            clickItem(selectAllButton)
            tryCompare(first, "selected", true)
            tryCompare(second, "selected", true)
            tryCompare(third, "selected", true)
            verify(deleteButton.enabled)

            clickItem(deleteButton)
            tryCompare(HistoryModel, "count", 0)
        }
    }
}
