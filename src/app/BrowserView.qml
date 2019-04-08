/*
 * Copyright 2013-2016 Canonical Ltd.
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
import QtQuick.Window 2.2
import Ubuntu.Components 1.3
import Ubuntu.Unity.Action 1.1 as UnityActions

FocusScope {
    property bool developerExtrasEnabled: false

    property var currentWebview: null
    property string title: currentWebview ? currentWebview.title : ""

    property var osk: _osk

    property bool hasTouchScreen: false

    // See http://design.canonical.com/2015/05/to-converge-onto-mobile-tablet-and-desktop-think-grid-units/
    readonly property bool wide: Window.contentItem.width >= units.gu(90)

    focus: true

    property QtObject actionManager: UnityActions.ActionManager {
        id: unityActionManager
        onQuit: Qt.quit()
    }
    property alias actions: unityActionManager.actions

    Rectangle {
      anchors.fill: parent
      color: theme.palette.normal.background
    }
    
    default property alias contents: contentsItem.data
    property alias automaticOrientation: contentsItem.automaticOrientation
    OrientationHelper {
        id: contentsItem

        KeyboardRectangle {
            id: _osk
        }
    }

    signal defaultVideoCaptureMediaIdUpdated(string defaultVideoCaptureDeviceId)

    /**
     * The goal of this chunk of code is to allow one to setup
     * a default selection for the camera based on its position.
     * As requested by:
     *   https://launchpad.net/bugs/1563398
     *
     * At the moment though, there is an Oxide bug that prevents
     * camera positions to be properly reported.
     *
     *   https://launchpad.net/bugs/1568145
     *
     * In order to workaround this for now, we use a hack based on the fact
     * that in hybris backed systems, the various video capture devices' names
     * are reported as "Front camera" & "Back camera", the string being translated.
     * We used this dirty heuristic instead of the position as a fallback for now.
     */

    property var currentWebcontext
    property string defaultVideoCaptureDeviceId
    property string defaultVideoCaptureDevicePosition: "frontface"

    QtObject {
        id: internal

        // "Front camera" is the user facing string returned by oxide
        // https://git.launchpad.net/oxide/tree/shared/browser/media/oxide_video_capture_device_factory_linux.cc#n49
        // It should be kept in sync.
        readonly property string defaultVideoCaptureDeviceUserName:
            (defaultVideoCaptureDevicePosition === "frontface") ?
                i18n.dtr("oxide-qt", "Front camera") : ""

        readonly property string cameraPositionUnspecified: "unspecified"

        function setupDefaultVideoCaptureDevice() {
            if ( ! currentWebcontext) {
                return
            }

            //var devices = Oxide.Oxide.availableVideoCaptureDevices

            if (! currentWebcontext.defaultVideoCaptureDeviceId
                    && devices
                    && devices.length > 0) {

                for (var i = 0; i < devices.length; ++i) {
                    /**
                     * defaultVideoCaptureDeviceId has precedence
                     */

                    if (defaultVideoCaptureDeviceId
                            && devices[i].id === defaultVideoCaptureDeviceId) {
                        currentWebcontext.defaultVideoCaptureDeviceId = devices[i].id
                        defaultVideoCaptureMediaIdUpdated(devices[i].id)
                        break
                    }

                    if (defaultVideoCaptureDevicePosition) {
                        if (devices[i].position === defaultVideoCaptureDevicePosition) {
                            currentWebcontext.defaultVideoCaptureDeviceId = devices[i].id
                            defaultVideoCaptureMediaIdUpdated(devices[i].id)
                            break
                        }

                        /**
                         * This is only there to act as a fallback with a reasonnable
                         * heuristic that tracks the case described above.
                         */
                        var displayName = devices[i].displayName
                        if (internal.defaultVideoCaptureDeviceUserName
                                && internal.cameraPositionUnspecified === devices[i].position
                                && displayName.indexOf(
                                    internal.defaultVideoCaptureDeviceUserName) === 0) {
                            currentWebcontext.defaultVideoCaptureDeviceId = devices[i].id
                            defaultVideoCaptureMediaIdUpdated(devices[i].id)
                            break
                        }
                    }
                }
            }
        }
    }

//    Connections {
//        target: Oxide.Oxide
//        onAvailableVideoCaptureDevicesChanged: internal.setupDefaultVideoCaptureDevice()
//    }
}
