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
import webbrowserapp.private 0.1

Item {
    id: root
    height: 100
    width: 100

    property Item containerLeft

    Item {
        id: containerRight
        anchors {
            bottom: parent.bottom
            left: parent.horizontalCenter
            right: parent.right
            top: parent.top
        }
    }

    function addExisting(container, tab) {
        tab.parent = container
    }

    function addExistingHelper(container, tab) {
        Reparenter.reparent(tab, container, {});
    }

    function builder(component, container) {
        return Reparenter.createObject(component, container)
    }

    TestCase {
        name: "Reparenter"
        when: windowShown

        function init() {
            var component = Qt.createComponent(Qt.resolvedUrl("ReparenterFakeContainer.qml"))
            containerLeft = component.createObject(root, {})
            containerLeft.root = root
        }

        function cleanup() {
            containerRight.children = null
        }

        function test_reparenter_cpp() {
            var tab = containerLeft.makeTabHelper()

            // Click on tab ensure it has been clicked
            mouseClick(root, 25, 50, Qt.LeftButton)
            compare(tab.mouseArea.clickCount, 1)

            // Move tab
            addExistingHelper(containerRight, tab)

            // Click on tab ensure it has been clicked
            mouseClick(root, 75, 50, Qt.LeftButton)
            compare(tab.mouseArea.clickCount, 2)

            // Destroy context
            containerLeft.destroy()

            // Click on tab ensure it has been clicked
            mouseClick(root, 75, 50, Qt.LeftButton)
            compare(tab.mouseArea.clickCount, 3)

            // Destroy object and check children have gone
            Reparenter.destroyContextAndObject(tab)
            tryCompare(tab, "mouseArea", undefined)
        }

        function test_reparenter_qml_expect_fail() {
            var tab = containerLeft.makeTab()

            // Click on tab ensure it has been clicked
            mouseClick(root, 25, 50, Qt.LeftButton)
            compare(tab.mouseArea.clickCount, 1)

            // Move tab
            addExisting(containerRight, tab)

            // Click on tab ensure it has been clicked
            mouseClick(root, 75, 50, Qt.LeftButton)
            compare(tab.mouseArea.clickCount, 2)

            // Destroy context
            containerLeft.destroy()

            // Attempt to click on tab find that children of tab have been
            // destroyed as the context has gone
            mouseClick(root, 75, 50, Qt.LeftButton)
            tryCompare(tab, "mouseArea", undefined)
        }
    }
}
