/*
 * Copyright 2013-2014 Canonical Ltd.
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

FocusScope {
    id: suggestions

    property var searchTerms
    property var models
    readonly property int count: suggestionsList.count
    property alias contentHeight: suggestionsList.contentHeight

    signal activated(url url)

    Rectangle {
        anchors.fill: parent
        radius: units.gu(0.5)
        border {
            color: "#dedede"
            width: 1
        }
    }

    clip: true

    ListView {
        id: suggestionsList
        anchors.fill: parent
        focus: true

        model: models.reduce(function(list, model) {
            var modelItems = [];

            // Models inheriting from QAbstractItemModel and JS arrays expose their
            // data differently, so we need to collect their items differently
            if (model.forEach) {
                model.forEach(function(item) { modelItems.push(item) })
            } else {
                for (var i = 0; i < model.count; i++) modelItems.push(model.get(i))
            }

            modelItems.forEach(function(item) {
                item["icon"] = model.icon
                item["displayUrl"] = model.displayUrl
                list.push(item);
            })
            return list;
        }, [])

        delegate: Suggestion {
            width: suggestionsList.width
            showDivider: index < model.length - 1

            title: highlightTerms(modelData.title)
            subtitle: modelData.displayUrl ? highlightTerms(modelData.url) : ""
            icon: modelData.icon
            selected: suggestionsList.activeFocus && ListView.isCurrentItem

            onActivated: suggestions.activated(modelData.url)
        }
    }

    Scrollbar {
        flickableItem: suggestionsList
        align: Qt.AlignTrailing
    }

    function escapeTerm(term) {
        // Build a regular expression suitable for highlighting a term
        // in a case-insensitive manner and globally, by escaping
        // special characters (a simpler version of preg_quote).
        var escaped = term.replace(/[().?]/g, '\\$&')
        return new RegExp(escaped, 'ig')
    }

    function highlightTerms(text) {
        // Highlight the matching terms (bold and Ubuntu orange)
        if (text === undefined) {
            return ''
        }
        var highlighted = text.toString()
        var count = searchTerms.length
        var highlight = '<b><font color="%1">$&</font></b>'.arg(UbuntuColors.orange)
        for (var i = 0; i < count; ++i) {
            var term = searchTerms[i]
            highlighted = highlighted.replace(escapeTerm(term), highlight)
        }
        highlighted = highlighted.replace(new RegExp('&', 'g'), '&amp;')
        highlighted = '<html>' + highlighted + '</html>'
        return highlighted
    }

    function countItems(total, model) {
        return total + (model.hasOwnProperty("length") ? model.length : model.count);
    }
}
