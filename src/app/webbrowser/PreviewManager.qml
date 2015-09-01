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

pragma Singleton

import QtQuick 2.4
import webbrowserapp.private 0.1

Item {
    signal previewSaved(url pageUrl, url previewUrl)

    LimitProxyModel {
        id: topSites
        limit: 10
        sourceModel: TopSitesModel {
            sourceModel: HistoryTimeframeModel {
                sourceModel: HistoryModel
            }
        }
        function contains(url) {
            for (var i = 0; i < topSites.count; i++) {
                if (topSites.get(i).url == url) return true
            }
            return false
        }
    }

    function previewPathFromUrl(url) {
        return "%1/%2.jpg".arg(internal.capturesDir).arg(Qt.md5(url))
    }

    function saveToDisk(data, url) {
        if (!FileOperations.exists(Qt.resolvedUrl(internal.capturesDir))) {
            FileOperations.mkpath(Qt.resolvedUrl(internal.capturesDir))
        }

        var filepath = previewPathFromUrl(url)
        var previewUrl = ""
        if (data.saveToFile(filepath)) previewUrl = Qt.resolvedUrl(filepath)
        else console.log("Failed to save preview to disk for %1 (path is %2)".arg(url).arg(filepath))

        previewSaved(url, previewUrl)
    }


    function checkDelete(url) {
        if (!topSites.contains(url)) {
            FileOperations.remove(Qt.resolvedUrl(previewPathFromUrl(url)))
        }
    }

    QtObject {
        id: internal
        property string capturesDir: cacheLocation + "/captures"
    }
}
