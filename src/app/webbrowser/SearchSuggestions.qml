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
import webbrowserapp.private 0.1

Item {
    property var terms
    property SearchEngine searchEngine
    property var results: []
    property bool active: false

    onSearchEngineChanged: resetSearch()
    onTermsChanged: resetSearch()
    onActiveChanged: resetSearch()

    QtObject {
        id: request

        property var xhr: null
        function get(url) {
            if (xhr === null) {
                xhr = new XMLHttpRequest()
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        results = parseResponse(xhr.responseText)
                    }
                }
            }
            xhr.open("GET", url);
            xhr.send();
        }

        function abort() {
            if (xhr) xhr.abort()
        }
    }

    Timer {
        id: limiter
        interval: 250
        onTriggered:  {
            if (terms.length > 0 && searchEngine) {
                var url = searchEngine.suggestionsUrlTemplate
                url = url.replace("{searchTerms}", encodeURIComponent(terms.join(" ")))
                request.get(url)
            }
        }
    }

    function parseResponse(response) {
        try {
            var data = JSON.parse(response)
        } catch (error) {
            return []
        }

        if (data.length > 1) {
            return data[1].map(function(result) {
                return {
                    title: result,
                    url: searchEngine.urlTemplate.replace("{searchTerms}",
                                                          encodeURIComponent(result))
                }
            })
        } else return []
    }

    function resetSearch() {
        results = []
        request.abort()
        if (active) limiter.restart()
    }
}
