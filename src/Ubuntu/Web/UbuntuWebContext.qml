/*
 * Copyright 2014-2015 Canonical Ltd.
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
import com.canonical.Oxide 1.9 as Oxide

Oxide.WebContext {
    id: oxideContext

    readonly property string defaultUserAgent: __ua.defaultUA

    dataPath: dataLocation

    cachePath: cacheLocation
    maxCacheSizeHint: cacheSizeHint

    userAgent: defaultUserAgent

    sessionCookieMode: {
        if (typeof webContextSessionCookieMode !== 'undefined') {
            if (webContextSessionCookieMode === "persistent") {
                return Oxide.WebContext.SessionCookieModePersistent
            } else if (webContextSessionCookieMode === "restored") {
                return Oxide.WebContext.SessionCookieModeRestored
            }
        }
        return Oxide.WebContext.SessionCookieModeEphemeral
    }

    userScripts: [
        Oxide.UserScript {
            context: "oxide://smartbanners/"
            url: Qt.resolvedUrl("smartbanners.js")
            incognitoEnabled: true
            matchAllFrames: true
        },
        Oxide.UserScript {
            context: "oxide://twitter-no-omniprompt/"
            url: Qt.resolvedUrl("twitter-no-omniprompt.js")
            incognitoEnabled: true
            matchAllFrames: true
        },
        Oxide.UserScript {
            context: "oxide://fb-no-appbanner/"
            url: Qt.resolvedUrl("fb-no-appbanner.js")
            incognitoEnabled: true
            matchAllFrames: true
        },
        Oxide.UserScript {
            context: "oxide://selection/"
            url: Qt.resolvedUrl("selection02.js")
            incognitoEnabled: true
            matchAllFrames: true
        }
    ]

    property QtObject __ua: UserAgent02 {
        onSmallScreenChanged: reloadOverrides()
        Component.onCompleted: reloadOverrides()

        property string _target: ""

        function reloadOverrides() {
            var target = smallScreen ? "mobile" : "desktop"
            if (target == _target) return
            _target = target
            var script = "ua-overrides-%1.js".arg(target)
            var temp = null
            try {
                temp = Qt.createQmlObject('import QtQml 2.0; import "%1" as Overrides; QtObject { readonly property var overrides: Overrides.overrides }'.arg(script), oxideContext)
            } catch (e) {
                console.error("No overrides found for", target)
            }
            if (temp !== null) {
                console.log("Loaded %1 UA override(s) from %2".arg(temp.overrides.length).arg(Qt.resolvedUrl(script)))
                userAgentOverrides = temp.overrides
                temp.destroy()
            }
        }
    }

    devtoolsEnabled: webviewDevtoolsDebugPort !== -1
    devtoolsPort: webviewDevtoolsDebugPort
    devtoolsIp: webviewDevtoolsDebugHost

    hostMappingRules: webviewHostMappingRules

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
    property QtObject __internal : QtObject {
        readonly property string cameraNamePrefixVideoCaptureDefault: (cameraPositionVideoCaptureDefault === "frontface") ? i18n.tr("Front") : ""
        readonly property string cameraPositionUnspecified: "unspecified"
    }

    property string cameraIdVideoCaptureDefault: webcontextDefaultCameraIdVideoCapture
    property string cameraPositionVideoCaptureDefault: webcontextDefaultVideoCaptureCameraPosition
    Component.onCompleted: {
        var OxideGlobals = Oxide.Oxide

        function updateDefaultVideoCaptureDevice() {
            var devices = OxideGlobals.availableVideoCaptureDevices

            if (! oxideContext.defaultVideoCaptureDeviceId
                    && devices
                    && devices.length > 0) {

                for (var i = 0; i < devices.length; ++i) {
                    /**
                     * cameraIdVideoCaptureDefault has precedence
                     */

                    if (cameraIdVideoCaptureDefault
                            && devices[i].id === cameraIdVideoCaptureDefault) {
                        oxideContext.defaultVideoCaptureDeviceId = devices[i].id
                        break
                    }

                    if (cameraPositionVideoCaptureDefault) {
                        if (devices[i].position === cameraPositionVideoCaptureDefault) {
                            oxideContext.defaultVideoCaptureDeviceId = devices[i].id
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
                            oxideContext.defaultVideoCaptureDeviceId = devices[i].id
                            break
                        }
                    }
                }
            }
        }

        var devices = OxideGlobals.availableVideoCaptureDevices
        if (devices.length !== 0) {
            updateDefaultVideoCaptureDevice()
        }
        OxideGlobals.availableVideoCaptureDevicesChanged.connect(function(){
            updateDefaultVideoCaptureDevice()
        })
    }
}
