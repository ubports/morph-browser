/*
 * Copyright 2015 Canonical Ltd.
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
import Qt.labs.folderlistmodel 2.1
import webbrowserapp.private 0.1

Item {
    id: searchEngines

    property var searchPaths: []
    readonly property var engines: ListModel {}

    Repeater {
        id: repeater
        model: searchEngines.searchPaths
        delegate: Item {
            property var folder: FolderListModel {
                folder: modelData
                showDirs: false
                nameFilters: ["*.xml"]
                sortField: FolderListModel.Name
                onCountChanged: delayedPopulation.restart()
            }
        }
        onItemRemoved: delayedPopulation.restart()
    }

    QtObject {
        id: internal

        function populateModel() {
            engines.clear()
            for (var i = repeater.count - 1; i >= 0; --i) {
                var folder = repeater.itemAt(i).folder
                for (var j = 0; j < folder.count; ++j) {
                    var name = folder.get(j, "fileBaseName")
                    var engine = searchEngineComponent.createObject(null, {filename: name})
                    var found = -1
                    for (var k = 0; k < engines.count; ++k) {
                        if (engines.get(k).filename == name) {
                            found = k
                            break
                        }
                    }
                    if (engine.valid && (found == -1)) {
                        var insertIndex = 0
                        for (var k = 0; k < engines.count; ++k) {
                            if (engines.get(k).filename > name) {
                                insertIndex = k
                                break
                            }
                        }
                        engines.insert(k, {"filename": name})
                    } else if (!engine.valid && (found > -1)) {
                        engines.remove(found)
                    }
                }
            }
        }
    }

    Timer {
        id: delayedPopulation
        interval: 50
        onTriggered: internal.populateModel()
    }

    Component {
        id: searchEngineComponent

        SearchEngine {
            searchPaths: searchEngines.searchPaths
        }
    }
}
