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
import webbrowserapp.private 0.1

QtObject {
    property var terms
    property SearchEngine searchEngine
    signal resultsAvailable(string results)

    property var request: new XMLHttpRequest()
    onSearchEngineChanged: reload()
    onTermsChanged: reload()

    Component.onCompleted: {
        request.onreadystatechange = function() {
            if (request.readyState === XMLHttpRequest.DONE) {
                resultsAvailable(request.responseText)
            }
        }
    }

    function reload() {
        if (!(terms.length > 0 && searchEngine)) {
            resultsAvailable([]);
            return;
        }

        var url = searchEngine.suggestionsUrlTemplate
        url = url.replace("{searchTerms}", encodeURIComponent(terms.join(" ")))

        request.open("GET", url);
        request.send();
    }
}
