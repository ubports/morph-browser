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

pragma Singleton

import QtQuick 2.4
import com.canonical.Oxide 1.9 as Oxide

QtObject {
    property var audioDevices: {
        var items = []
        for (var i = 0; i < Oxide.Oxide.availableAudioCaptureDevices.length; i++) {
            items.push(Oxide.Oxide.availableAudioCaptureDevices[i].id)
        }
        return items
    }
    property var videoDevices: {
        var items = []
        for (var i = 0; i < Oxide.Oxide.availableVideoCaptureDevices.length; i++) {
            items.push(Oxide.Oxide.availableVideoCaptureDevices[i].id)
        }
        return items
    }
}
