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

// A specialized ScrollTracker that handles automatically showing/hiding
// the chrome for a given webview, based on scroll events and proximity to
// the top/bottom of the page, as well as whether the webview is currently
// fullscreen.
ScrollTracker {
    id: chromeStateTracker

    active: webview && !webview.fullscreen

    onScrolledUp: {
        if (!header.moving && chromeStateChangeTimer.settled) {
            delayedAutoHideTimer.up = true
            delayedAutoHideTimer.restart()
        }
    }
    onScrolledDown: {
        if (!header.moving && chromeStateChangeTimer.settled) {
            delayedAutoHideTimer.up = false
            delayedAutoHideTimer.restart()
        }
    }

    // Delay the auto-hide/auto-show behaviour of the header, in order
    // to prevent the view from jumping up and down on touch-enabled
    // devices when the touch event sequence is not finished.
    // See https://bugs.launchpad.net/morph-browser/+bug/1354700.
    Timer {
        id: delayedAutoHideTimer
        interval: 250
        property bool up
        onTriggered: {
            if (up) {
                chromeStateTracker.header.state = "shown"
            } else {
                if (chromeStateTracker.nearBottom) {
                    chromeStateTracker.header.state = "shown"
                } else if (!chromeStateTracker.nearTop) {
                    chromeStateTracker.header.state = "hidden"
                }
            }
        }
    }

    // After the chrome has stopped moving (either fully shown or fully
    // hidden), give it some time to "settle". Until it is settled,
    // scroll events won’t trigger a new change in the chrome’s
    // visibility, to prevent the chrome from jumping back into view if
    // it has just been hidden.
    // See https://bugs.launchpad.net/morph-browser/+bug/1354700.
    Timer {
        id: chromeStateChangeTimer
        interval: 50
        running: !chromeStateTracker.header.moving
        onTriggered: settled = true
        property bool settled: true
    }

    Connections {
        target: chromeStateTracker.header
        onMovingChanged: chromeStateChangeTimer.settled = false
    }
}
