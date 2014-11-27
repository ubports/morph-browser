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
        }

        SignalSpy {
            id: spy
            target: capture
            signalName: "scheduledUpdateCompleted"
        }
    }

    Image {
        id: image
    }

    TestCase {
        name: "ItemCapture"
        when: windowShown

        function test_capture() {
            spy.wait()
            image.source = capture.capture("test")
            compare(image.status, Image.Ready)
            compare(image.sourceSize.width, rect.width)
            compare(image.sourceSize.height, rect.height)
        }
    }
}
