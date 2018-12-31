/*
 * Copyright 2013-2015 Canonical Ltd.
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
import "Highlight.js" as Highlight

FocusScope {
    id: suggestions

    property var searchTerms
    property var models

    readonly property int count: models.reduce(internal.countItems, 0)
    readonly property alias contentHeight: suggestionsList.contentHeight

    signal activated(url url)

    Rectangle {
        anchors.fill: parent
        radius: units.gu(0.5)
        border {
            color: theme.palette.normal.base
            width: 1
        }
    }

    clip: true

    ListView {
        id: suggestionsList
        objectName: "suggestionsList"
        anchors.fill: parent
        focus: true

        model: models.reduce(function(list, model) {
            var modelItems = []

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
                list.push(item)
            })
            return list
        }, [])

        delegate: Suggestion {
            objectName: "suggestionDelegate_" + index
            width: suggestionsList.width
            showDivider: index < model.length - 1

            title: selected ? modelData.title : Highlight.highlightTerms(modelData.title, searchTerms)
            subtitle: modelData.displayUrl ? (selected ? modelData.url :
                                                         Highlight.highlightTerms(modelData.url, searchTerms)) : ""
            icon: modelData.icon || ""
            selected: suggestionsList.activeFocus && ListView.isCurrentItem

            onActivated: suggestions.activated(modelData.url)
        }
    }

    Scrollbar {
        flickableItem: suggestionsList
        align: Qt.AlignTrailing
    }

    QtObject {
        id: internal

        function countItems(total, model) {
            return total + (model.hasOwnProperty("length") ? model.length : model.count)
        }
    }
}
