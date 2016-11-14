/*
 * Copyright (C) 2016 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Andrew Hayzen <andrew.hayzen@canonical.com>
 */
import QtQuick 2.4

QtObject {
    property var dropArea: null
    property bool enabled: false
    property var expectedAction: Qt.IgnoreAction | Qt.CopyAction | Qt.MoveAction
    property string mimeType: "x-tabsbar/tab"
    property real previewBorderWidth: units.gu(1)
    property var previewSize: Qt.size(units.gu(35), units.gu(22.5))
    property real previewTopCrop: 0
    property var previewUrlFromIndex: function(index) {
        return "";
    }
    property var thisWindow: null
}