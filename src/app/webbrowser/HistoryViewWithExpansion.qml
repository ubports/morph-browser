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

FocusScope {
    id: historyViewWithExpansion

    function loadModel() {
        historyView.loadModel()
    }

    signal newTabRequested()
    signal historyEntryClicked(url url)
    signal done()
    signal back()

    HistoryView {
        id: historyView
        anchors.fill: parent
        focus: !expandedHistoryViewLoader.focus
        visible: focus
        onSeeMoreEntriesClicked: {
            expandedHistoryViewLoader.model = model
            expandedHistoryViewLoader.active = true
        }
        onNewTabRequested: historyViewWithExpansion.newTabRequested()
        onBack: historyViewWithExpansion.back()
    }
    
    Loader {
        id: expandedHistoryViewLoader
        asynchronous: true
        anchors.fill: parent
        active: false
        focus: active
        property var model: null
        sourceComponent: ExpandedHistoryView {
            focus: true
            model: expandedHistoryViewLoader.model
            onHistoryEntryClicked: historyViewWithExpansion.historyEntryClicked(url)
            onHistoryEntryRemoved: {
                if (count == 1) {
                    done()
                }
                HistoryModel.removeEntryByUrl(url)
            }
            onDone: expandedHistoryViewLoader.active = false
        }
    }
}
