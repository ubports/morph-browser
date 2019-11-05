/*
* Copyright 2015-2016 Canonical Ltd.
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

Page {
    id: page

    property bool showBackAction: true
    property list<Action> leadingActions
    property list<Action> trailingActions
    property alias title: pageHeader.title
    property alias subtitle: pageHeader.subtitle
    property alias headerContents: pageHeader.contents

    default property alias contents: contentsItem.data

    signal back()

    Keys.onEscapePressed: back()

    MouseArea {
        // Prevent click events from propagating through to the view below the page
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    header: PageHeader {
        id: pageHeader
        StyleHints {
            backgroundColor: theme.palette.normal.foreground
        }
        leadingActionBar.actions: page.showBackAction ? [backAction] : page.leadingActions
        trailingActionBar.actions: page.trailingActions
    }

    Action {
        id: backAction
        objectName: "back"
        iconName: "back"
        onTriggered: page.back()
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.foreground
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            contentsItem.forceActiveFocus()
        }
    }

    FocusScope {
        id: contentsItem
        anchors {
            top: pageHeader.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }
}
