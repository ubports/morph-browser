/*
 * Copyright 2015 Canonical Ltd.
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

Item {
    property bool isAudio
    readonly property int devicesCount: internal.devices.length
    property alias enabled: selector.enabled
    property string defaultDevice
    signal deviceSelected(string id)

    implicitHeight: selector.height + units.gu(1)

    OptionSelector {
        id: selector

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: units.gu(1)
        containerHeight: itemHeight * model.length

        model: internal.devices
        delegate: OptionSelectorDelegate {
            text: modelData.displayName || i18n.tr("Default")
        }
        onDelegateClicked: deviceSelected(model[index].id)
    }

    QtObject {
        id: internal

        property var devices: []//isAudio ? Oxide.availableAudioCaptureDevices :
                              //          Oxide.availableVideoCaptureDevices

        function updateDefaultDevice() {
            for (var i = 0; i < devices.length; i++) {
                if (defaultDevice === devices[i].id) {
                    selector.selectedIndex = i
                    return
                }
            }
        }
    }

    onDefaultDeviceChanged: internal.updateDefaultDevice()
    Connections {
        target: Oxide
        onAvailableAudioCaptureDevicesChanged: if (isAudio) internal.updateDefaultDevice()
        onAvailableVideoCaptureDevicesChanged: if (!isAudio) internal.updateDefaultDevice()
    }

    onIsAudioChanged: internal.updateDefaultDevice()
}
