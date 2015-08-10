/*
 * Copyright 2013-2015 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Unity.Action 1.1 as UnityActions

Item {
    property bool developerExtrasEnabled: false

    property var currentWebview: null
    property string title: currentWebview ? currentWebview.title : ""

    property var initialUrls

    property var webbrowserWindow: null

    property var osk: _osk

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
}
