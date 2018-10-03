/*
 * Copyright 2015-2016 Canonical Ltd.
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

GridView {
    id: grid

    property bool showFavicons: true
    property int horizontalMargin: units.gu(3)
    property int verticalMargin: units.gu(2.5)
    property int previewWidth: units.gu(17)
    property int previewHeight: units.gu(10)

    signal activated(url url)
    signal removed(url url)

    cellWidth: previewWidth + horizontalMargin * 2
    cellHeight: previewHeight + verticalMargin * 2 + units.gu(4) // height of text + favicon + margins in delegate

    delegate: UrlPreviewDelegate {
        objectName: "topSiteItem"
        width: grid.cellWidth
        height: grid.cellHeight

        title: model.title
        icon: model.icon
        url: model.url
        showFavicon: grid.showFavicons

        previewHeight: grid.previewHeight
        previewWidth: grid.previewWidth

        onClicked: grid.activated(model.url)
        onSetCurrent: grid.currentIndex = index
        onRemoved: grid.removed(model.url)
    }

    highlight: Item {
        visible: viewHighlight.hasKeyboard && GridView.view && GridView.view.activeFocus
        ListViewHighlight {
            id: viewHighlight
            visible: true
            width: previewWidth + units.gu(2)
            height: previewHeight + units.gu(5)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: (grid.cellHeight - height) / 2 - grid.verticalMargin - units.gu(0.5)
                leftMargin: (grid.cellWidth - width) / 2 - grid.horizontalMargin
            }
        }
    }

    Keys.onDeletePressed: removed(currentItem.url)

    Keys.onUpPressed: {
        var current = currentIndex
        moveCurrentIndexUp()
        if (current == currentIndex) {
            event.accepted = false
        }
    }
    Keys.onDownPressed: {
        var current = currentIndex
        moveCurrentIndexDown()
        if (currentIndex == current) {
            event.accepted = false
        }
    }

    Timer {
        // Work around a weird issue with the use of a LimitProxyModel in a
        // grid view, where the currentIndex is changed when populating the
        // model.
        running: true
        interval: 1
        onTriggered: grid.currentIndex = 0
    }
}
