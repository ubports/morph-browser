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
import Ubuntu.Components 1.3
import "." // QTBUG-34418

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
        onDelegateClicked: deviceSelected(model[index])
    }

    QtObject {
        id: internal

        property var devices: isAudio ? InputDevicesModel.audioDevices :
                                        InputDevicesModel.videoDevices

        function updateDefaultDevice() {
            for (var i = 0; i < devices.length; i++) {
                if (defaultDevice === devices[i]) {
                    selector.selectedIndex = i;
                    return;
                }
            }
        }
    }

    onDefaultDeviceChanged: internal.updateDefaultDevice()
    Connections {
        target: InputDevicesModel
        onAudioDevicesChanged: if (isAudio) internal.updateDefaultDevice()
        onVideoDevicesChanged: if (!isAudio) internal.updateDefaultDevice()
    }
}

