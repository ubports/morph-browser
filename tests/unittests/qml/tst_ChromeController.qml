/*
 * Copyright 2016 Canonical Ltd.
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
import QtTest 1.0
import com.canonical.Oxide 1.7 as Oxide
import "../../../src/app"

ChromeController {
    id: controller

    Item {
        id: webviewMock
        property bool loading: false
        readonly property bool loadingState: loading
        property bool fullscreen: false
        property var locationBarController: QtObject {
            property bool animated: false
            property int mode: controller.defaultMode
            signal show(bool animate)
        }
        signal loadEvent(var event)
    }

    SignalSpy {
        id: showSpy
        target: webviewMock.locationBarController
        signalName: "show"
    }

    webview: webviewMock

    TestCase {
        name: "ChromeController"

        readonly property int modeAuto: Oxide.LocationBarController.ModeAuto
        readonly property int modeShown: Oxide.LocationBarController.ModeShown
        readonly property int modeHidden: Oxide.LocationBarController.ModeHidden

        function init() {
            controller.forceHide = false
            controller.forceShow = false
            controller.defaultMode = modeAuto
            webviewMock.loading = false
            webviewMock.fullscreen = false
            webviewMock.locationBarController.animated = false
            webviewMock.locationBarController.mode = controller.defaultMode
            showSpy.clear()
        }

        function test_change_webview_data() {
            return [
                {forceHide: false, forceShow: false, fullscreen: false,
                 mode: modeAuto, shown: true},
                {forceHide: false, forceShow: true, fullscreen: false,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: false, fullscreen: true,
                 mode: modeAuto, shown: false},
                {forceHide: false, forceShow: true, fullscreen: true,
                 mode: modeShown, shown: false},
                {forceHide: true, forceShow: false, fullscreen: true,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: true, fullscreen: false,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: true, fullscreen: true,
                 mode: modeHidden, shown: false},
            ]
        }

        function test_change_webview(data) {
            controller.webview = null
            controller.forceHide = data.forceHide
            controller.forceShow = data.forceShow
            webviewMock.fullscreen = data.fullscreen
            showSpy.clear()
            controller.webview = webviewMock
            compare(webviewMock.locationBarController.mode, data.mode)
            compare(showSpy.count, data.shown ? 1 : 0)
        }

        function test_change_forceHide_data() {
            return [
                {forceShow: false, fullscreen: false,
                 modes: [modeAuto, modeHidden, modeAuto], shown: 1},
                {forceShow: true, fullscreen: false,
                 modes: [modeShown, modeHidden, modeShown], shown: 0},
                {forceShow: false, fullscreen: true,
                 modes: [modeHidden, modeHidden, modeHidden], shown: 0},
                {forceShow: true, fullscreen: true,
                 modes: [modeHidden, modeHidden, modeShown], shown: 0},
            ]
        }

        function test_change_forceHide(data) {
            controller.forceShow = data.forceShow
            webviewMock.fullscreen = data.fullscreen
            showSpy.clear()
            controller.forceHide = false
            compare(webviewMock.locationBarController.mode, data.modes[0])
            controller.forceHide = true
            compare(webviewMock.locationBarController.mode, data.modes[1])
            controller.forceHide = false
            compare(webviewMock.locationBarController.mode, data.modes[2])
            compare(showSpy.count, data.shown)
        }

        function test_change_forceShow_data() {
            return [
                {forceHide: false, fullscreen: false,
                 modes: [modeAuto, modeShown, modeAuto], shown: 1},
                {forceHide: true, fullscreen: false,
                 modes: [modeHidden, modeHidden, modeHidden], shown: 0},
                {forceHide: false, fullscreen: true,
                 modes: [modeHidden, modeShown, modeShown], shown: 0},
                {forceHide: true, fullscreen: true,
                 modes: [modeHidden, modeHidden, modeHidden], shown: 0},
            ]
        }

        function test_change_forceShow(data) {
            controller.forceHide = data.forceHide
            webviewMock.fullscreen = data.fullscreen
            showSpy.clear()
            controller.forceShow = false
            compare(webviewMock.locationBarController.mode, data.modes[0])
            controller.forceShow = true
            compare(webviewMock.locationBarController.mode, data.modes[1])
            controller.forceShow = false
            compare(webviewMock.locationBarController.mode, data.modes[2])
            compare(showSpy.count, data.shown)
        }

        function test_change_fullscreen_data() {
            return [
                {forceHide: false, forceShow: false, defaultMode: modeAuto,
                 mode: modeAuto, shown: true},
                {forceHide: false, forceShow: false, defaultMode: modeShown,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: false, defaultMode: modeHidden,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: false, defaultMode: modeAuto,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: false, defaultMode: modeShown,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: false, defaultMode: modeHidden,
                 mode: modeHidden, shown: false},
                {forceHide: false, forceShow: true, defaultMode: modeAuto,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: true, defaultMode: modeShown,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: true, defaultMode: modeHidden,
                 mode: modeShown, shown: false},
                {forceHide: true, forceShow: true, defaultMode: modeAuto,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: true, defaultMode: modeShown,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: true, defaultMode: modeHidden,
                 mode: modeHidden, shown: false},
            ]
        }

        function test_change_fullscreen(data) {
            webviewMock.fullscreen = false
            controller.forceHide = data.forceHide
            controller.forceShow = data.forceShow
            controller.defaultMode = data.defaultMode
            showSpy.clear()
            webviewMock.fullscreen = true
            compare(webviewMock.locationBarController.mode, modeHidden)
            compare(showSpy.count, 0)
            webviewMock.fullscreen = false
            compare(webviewMock.locationBarController.mode, data.mode)
            compare(showSpy.count, data.shown ? 1 : 0)
        }

        function test_loading_state_changed_data() {
            return [
                {forceHide: false, forceShow: false, fullscreen: false,
                 mode: modeAuto, shown: true},
                {forceHide: false, forceShow: false, fullscreen: false,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: false, fullscreen: false,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: false, fullscreen: false,
                 mode: modeHidden, shown: false},
                {forceHide: false, forceShow: true, fullscreen: false,
                 mode: modeShown, shown: false},
                {forceHide: false, forceShow: false, fullscreen: true,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: true, fullscreen: false,
                 mode: modeHidden, shown: false},
                {forceHide: true, forceShow: false, fullscreen: true,
                 mode: modeHidden, shown: false},
                {forceHide: false, forceShow: true, fullscreen: true,
                 mode: modeShown, shown: false},
                {forceHide: true, forceShow: true, fullscreen: true,
                 mode: modeHidden, shown: false},
            ]
        }

        function test_loading_state_changed(data) {
            controller.forceHide = data.forceHide
            controller.forceShow = data.forceShow
            webviewMock.fullscreen = data.fullscreen
            webviewMock.locationBarController.mode = data.mode
            showSpy.clear()
            webviewMock.loading = true
            compare(showSpy.count, data.shown ? 1 : 0)
            compare(webviewMock.locationBarController.mode, data.mode)
            showSpy.clear()
            webviewMock.loading = false
            compare(showSpy.count, 0)
            compare(webviewMock.locationBarController.mode, data.mode)
        }

        function test_load_event_data() {
            var data = []
            var booleanValues = [false, true]
            var modeValues = [modeAuto, modeHidden, modeShown]
            for (var i in booleanValues) {
                for (var j in booleanValues) {
                    for (var k in modeValues) {
                        for (var l in modeValues) {
                            data.push({forceHide: booleanValues[i], forceShow: booleanValues[j],
                                       initialMode: modeValues[k], defaultMode: modeValues[l]})
                        }
                    }
                }
            }
            return data
        }

        function test_load_event(data) {
            // event types
            var started = Oxide.LoadEvent.TypeStarted
            var committed = Oxide.LoadEvent.TypeCommitted
            var succeeded = Oxide.LoadEvent.TypeSucceeded
            var stopped = Oxide.LoadEvent.TypeStopped
            var failed = Oxide.LoadEvent.TypeFailed
            var redirected = Oxide.LoadEvent.TypeRedirected

            controller.forceHide = data.forceHide
            controller.forceShow = data.forceShow
            controller.defaultMode = data.defaultMode
            webviewMock.locationBarController.mode = data.initialMode
            showSpy.clear()

            function test_sequence(sequence, modes) {
                for (var i in sequence) {
                    webviewMock.loadEvent({type: sequence[i]})
                    if (data.forceHide || data.forceShow) {
                        compare(webviewMock.locationBarController.mode, data.initialMode)
                    } else {
                        compare(webviewMock.locationBarController.mode, modes[i])
                    }
                    compare(showSpy.count, 0)
                }
            }

            var sequence = [started, committed, succeeded]
            var modes = [modeShown, data.defaultMode, data.defaultMode]
            test_sequence(sequence, modes)

            sequence = [started, stopped]
            modes = [modeShown, data.defaultMode]
            test_sequence(sequence, modes)

            sequence = [started, failed, committed]
            modes = [modeShown, modeShown, data.defaultMode]
            test_sequence(sequence, modes)

            sequence = [started, redirected, committed, succeeded]
            modes = [modeShown, modeShown, data.defaultMode, data.defaultMode]
            test_sequence(sequence, modes)
        }
    }
}
