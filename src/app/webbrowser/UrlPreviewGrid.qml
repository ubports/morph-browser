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

import QtQuick 2.4
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3
import webbrowserapp.private 0.1
import ".."

GridView {
    id: grid

    property bool showFavicons: true
    property int rightMargin: units.gu(6)
    property int bottomMargin: units.gu(5)
    property int previewWidth: units.gu(17)
    property int previewHeight: units.gu(10)

    signal activated(url url)
    signal removed(url url)
    signal releasingKeyboardFocus()

    currentIndex: 0

    cellWidth: previewWidth + rightMargin
    cellHeight: previewHeight + bottomMargin + units.gu(4) // height of text + favicon + margin in delegate

    implicitHeight: contentItem.childrenRect.height

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
        onRemoved: grid.removed(model.url)
    }

    highlight: Component {
        Item {
            visible: grid.activeFocus
            UbuntuShape {
                anchors.fill: parent
                anchors.leftMargin: - grid.rightMargin * 0.5
                anchors.rightMargin: grid.rightMargin * 0.5
                anchors.topMargin: - grid.bottomMargin * 0.5
                anchors.bottomMargin: grid.bottomMargin * 0.5
                aspect: UbuntuShape.Flat
                backgroundColor: Qt.rgba(0, 0, 0, 0.05)
            }
        }
    }

    Keys.onDeletePressed: removed(currentItem.url)

    Keys.onLeftPressed: {
        var i = grid.currentIndex
        grid.moveCurrentIndexLeft()
        if (i === grid.currentIndex) grid.releasingKeyboardFocus()
    }

    Keys.onUpPressed: {
        var i = grid.currentIndex
        grid.moveCurrentIndexUp()
        if (i === grid.currentIndex) grid.releasingKeyboardFocus()
    }
}
