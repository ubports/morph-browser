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

ListModel {
    id: searchSuggestions

    property int limit: 0
    property int start: 0
    property SearchSuggestions source

    onSourceChanged: setupConnections()
    onLimitChanged: update()
    onStartChanged: update()

    property var _results

    function setupConnections() {
        if (source) source.resultsAvailable.connect(function(results) {
            try {
                var resultsGroup = JSON.parse(results)
                if (resultsGroup.length > 1) {
                    _results = resultsGroup[1];
                }
            }
            catch (error) { return }
            update()
        })
    }

    function update() {
        searchSuggestions.clear();
        if (_results) {
            _results.slice(start, start + limit).forEach(function(result) {
                searchSuggestions.append({
                    title: result,
                    url: source.searchEngine.urlTemplate.replace("{searchTerms}", encodeURIComponent(result))
                })
            })
        }
    }
}
