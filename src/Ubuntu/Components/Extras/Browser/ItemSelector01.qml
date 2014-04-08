/*
 * Copyright 2013 Canonical Ltd.
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
import Ubuntu.Components 0.1
import Ubuntu.Components.ListItems 0.1 as ListItem
import Ubuntu.Components.Popups 0.1

Popover {
    id: itemSelector

    property QtObject selectorModel: model

    caller: parent
    contentWidth: Math.min(parent.width - units.gu(10), units.gu(40))
    property real listContentHeight: 0 // intermediate property to avoid binding loop
    contentHeight: Math.min(parent.height - units.gu(10), listContentHeight)

    ListView {
        clip: true
        width: itemSelector.contentWidth
        height: itemSelector.contentHeight

        model: selectorModel.items

        delegate: ListItem.Standard {
            text: model.text
            enabled: model.enabled
            selected: model.selected
            onClicked: selectorModel.accept(model.index)
        }

        section.property: "group"
        section.delegate: ListItem.Header {
            text: section
        }

        onContentHeightChanged: itemSelector.listContentHeight = contentHeight
    }

    Component.onCompleted: show()

    onVisibleChanged: {
        if (!visible) {
            selectorModel.reject()
        }
    }
}
