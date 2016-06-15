/*
 * Copyright 2013-2016 Canonical Ltd.
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
import Ubuntu.Unity.Action 1.1 as UnityActions
import com.canonical.Oxide 1.15 as Oxide

FocusScope {
    property bool developerExtrasEnabled: false

    property var currentWebview: null
    property string title: currentWebview ? currentWebview.title : ""

    property var initialUrls

    property var webbrowserWindow: null

    property var osk: _osk

    property bool hasTouchScreen: false

    // See http://design.canonical.com/2015/05/to-converge-onto-mobile-tablet-and-desktop-think-grid-units/
    readonly property bool wide: width >= units.gu(90)

    focus: true

    property QtObject actionManager: UnityActions.ActionManager {
        id: unityActionManager
        onQuit: Qt.quit()
    }
    property alias actions: unityActionManager.actions

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

    property var currentWebviewContext
    property string cameraIdVideoCaptureDefault
    property string cameraPositionVideoCaptureDefault: "frontface"

    property QtObject __internal : QtObject {
        readonly property string cameraNamePrefixVideoCaptureDefault:
            (cameraPositionVideoCaptureDefault === "frontface") ?
                i18n.tr("Front") : ""

        readonly property string cameraPositionUnspecified: "unspecified"

        function setupDefaultVideoCaptureDevice() {
            if ( ! currentWebviewContext) {
                return
            }

            var OxideGlobals = Oxide.Oxide

            function updateDefaultVideoCaptureDevice(thisSlot) {
                var devices = OxideGlobals.availableVideoCaptureDevices

                if (! currentWebviewContext.defaultVideoCaptureDeviceId
                        && devices
                        && devices.length > 0) {

                    for (var i = 0; i < devices.length; ++i) {
                        /**
                         * cameraIdVideoCaptureDefault has precedence
                         */

                        if (cameraIdVideoCaptureDefault
                                && devices[i].id === cameraIdVideoCaptureDefault) {
                            currentWebviewContext.defaultVideoCaptureDeviceId = devices[i].id
                            defaultVideoCaptureMediaIdUpdated(devices[i].id)
                            break
                        }

                        if (cameraPositionVideoCaptureDefault) {
                            if (devices[i].position === cameraPositionVideoCaptureDefault) {
                                currentWebviewContext.defaultVideoCaptureDeviceId = devices[i].id
                                defaultVideoCaptureMediaIdUpdated(devices[i].id)
                                break
                            }

                            /**
                             * This is only there to act as a fallback with a reasonnable
                             * heuristic that tracks the case described above.
                             */
                            var displayName = devices[i].displayName
                            if (__internal.cameraNamePrefixVideoCaptureDefault
                                    && __internal.cameraPositionUnspecified === devices[i].position
                                    && displayName.indexOf(
                                        __internal.cameraNamePrefixVideoCaptureDefault) === 0) {
                                currentWebviewContext.defaultVideoCaptureDeviceId = devices[i].id
                                defaultVideoCaptureMediaIdUpdated(devices[i].id)
                                break
                            }
                        }
                    }

                    if (i < devices.length && thisSlot) {
                        OxideGlobals.availableVideoCaptureDevicesChanged.disconnect(
                                    thisSlot)
                    }
                }
            }

            var devices = OxideGlobals.availableVideoCaptureDevices
            if (devices.length !== 0) {
                updateDefaultVideoCaptureDevice()
            } else {
                var onVideoDevicesChanges = function(){
                    updateDefaultVideoCaptureDevice(
                                onVideoDevicesChanges)
                }
                OxideGlobals.availableVideoCaptureDevicesChanged.connect(onVideoDevicesChanges)
            }
        }
    }


    Component.onCompleted: {
        if (! currentWebviewContext) {
            currentWebviewContextChanged.connect(__internal.setupDefaultVideoCaptureDevice)
        } else {
            __internal.setupDefaultVideoCaptureDevice()
        }
    }
}
