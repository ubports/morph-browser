/*
 * Copyright 2014 Canonical Ltd.
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

import QtQuick 2.0
import QtTest 1.0
import webbrowserapp.private 0.1

Item {
    width: 200
    height: 200

    Rectangle {
        id: rect

        width: 123
        height: 157
        color: "red"
        anchors.centerIn: parent

        ItemCapture {
            id: capture
            onCaptureFinished: image.source = capture
        }

        SignalSpy {
            id: spyReady
            target: capture
            signalName: "scheduledUpdateCompleted"
        }

        SignalSpy {
            id: spyCaptured
            target: capture
            signalName: "captureFinished"
        }
    }

    Image {
        id: image
    }

    TestCase {
        name: "ItemCapture"
        when: windowShown

        function test_quality_data() {
            return [
                {get: -1},
                {set: 58, get: 58},
                {set: 122},
                {set: -39},
                {set: -1, get: -1},
                {set: 0, get: 0},
                {set: 100, get: 100}
            ]
        }

        function test_quality(data) {
            var quality = capture.quality
            if ('set' in data) {
                capture.quality = data.set
            }
            if ('get' in data) {
                compare(capture.quality, data.get)
            } else {
                compare(capture.quality, quality)
            }
        }

        function test_capture() {
            spyReady.wait()
            spyCaptured.clear()
            var id = "test"
            capture.requestCapture(id)
            spyCaptured.wait()
            compare(spyCaptured.signalArguments[0][0], id)
            verify(image.source.toString())
            compare(image.status, Image.Ready)
            compare(image.sourceSize.width, rect.width)
            compare(image.sourceSize.height, rect.height)
        }

        function test_capture_invalid_id() {
            spyReady.wait()
            spyCaptured.clear()
            var invalid = "foo/bar"
            capture.requestCapture(invalid)
            spyCaptured.wait()
            compare(spyCaptured.signalArguments[0][0], invalid)
            verify(!spyCaptured.signalArguments[0][1].toString())
        }
    }
}
