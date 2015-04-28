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
import Qt.labs.folderlistmodel 2.1
import webbrowserapp.private 0.1

Item {
    id: searchEngines

    property var searchPaths: []

    QtObject {
        id: internal
        property var folderListModels: searchPaths.map(function(folder) {
            return folderModelComponent.createObject(null, {folder: folder})
        })
    }

    property var engines: {
        var r = []
        for (var i = searchPaths.length - 1; i >= 0; --i) {
            var folder = internal.folderListModels[i]
            for (var j = 0; j < folder.count; ++j) {
                var name = folder.get(j, "fileBaseName")
                var engine = searchEngineComponent.createObject(null, {filename: name})
                var found = r.indexOf(name)
                if (engine.valid && (found == -1)) {
                    r.push(name)
                } else if (!engine.valid && (found > -1)) {
                    r.splice(found, 1)
                }
            }
        }
        r.sort()
        return r
    }

    Component {
        id: folderModelComponent

        FolderListModel {
            showDirs: false
            nameFilters: ["*.xml"]
            sortField: FolderListModel.Name
        }
    }

    Component {
        id: searchEngineComponent

        SearchEngine {
            searchPaths: searchEngines.searchPaths
        }
    }
}
