/*
 * Copyright 2014 Canonical Ltd.
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

Item {
    id: scrollTracker

    property var webview
    property var header

    readonly property bool nearTop: webview ? webview.contentY < (internal.headerHeight / internal.contentRatio) : false
    readonly property bool nearBottom: webview ? (webview.contentY + internal.viewportHeight + internal.headerHeight / internal.contentRatio) > internal.contentHeight : false

    property bool active: true

    signal scrolledUp()
    signal scrolledDown()

    enabled: false
    visible: false

    QtObject {
        id: internal

        readonly property real headerHeight: scrollTracker.header ? scrollTracker.header.height : 0
        readonly property real headerVisibleHeight: scrollTracker.header ? scrollTracker.header.visibleHeight : 0

        readonly property real contentHeight: scrollTracker.webview ? scrollTracker.webview.contentHeight + headerVisibleHeight : 0.0
        readonly property real viewportHeight: scrollTracker.webview ? scrollTracker.webview.viewportHeight + headerVisibleHeight : 0.0
        readonly property real maxContentY: scrollTracker.webview ? scrollTracker.webview.contentHeight - scrollTracker.webview.viewportHeight : 0.0

        readonly property real contentRatio: scrollTracker.webview ? scrollTracker.webview.viewportHeight / scrollTracker.webview.contentHeight : 1.0

        readonly property real currentScrollFraction: (maxContentY == 0.0) ? 0.0 : (scrollTracker.webview.contentY / maxContentY)
        property real previousScrollFraction: 0.0
    }

    Connections {
        target: scrollTracker.active ? scrollTracker.webview : null
        onContentYChanged: {
            var old = internal.previousScrollFraction
            internal.previousScrollFraction = internal.currentScrollFraction
            if (internal.currentScrollFraction < old) {
                scrollTracker.scrolledUp()
            } else if (internal.currentScrollFraction > old) {
                scrollTracker.scrolledDown()
            }
        }
    }
}
