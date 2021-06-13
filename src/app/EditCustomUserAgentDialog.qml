/*
 * Copyright 2020 UBports Foundation
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

import QtQuick 2.9
import Ubuntu.Components 1.3 as UITK
import Ubuntu.Components.Popups 1.3 as Popups
import Ubuntu.Content 1.3
import webbrowsercommon.private 0.1

Popups.Dialog {
    id: editCustomUserAgent

    property string previousUserAgentName: ""
    property alias userAgentName: editUserAgentName.text
    property alias userAgentString: editUserAgentString.text

    readonly property bool userAgentNameAlreadyTaken: (userAgentName !== previousUserAgentName) && UserAgentsModel.contains(userAgentName)

    signal accept(string userAgentName, string userAgentString)
    signal cancel()

    onAccept: hide()
    onCancel: hide()

    UITK.Label {
        visible: userAgentNameAlreadyTaken
        text: i18n.tr("this user agent name is already taken")
        color: theme.palette.normal.negative
    }

    UITK.TextField {
        id: editUserAgentName
        placeholderText: i18n.tr("Add the name for the user agent")
        inputMethodHints: Qt.ImhNoPredictiveText
    }

    UITK.TextArea {
        id: editUserAgentString
        placeholderText: i18n.tr("enter user agent string...")
        inputMethodHints: Qt.ImhNoPredictiveText
    }

    Row {
        spacing: units.gu(2)

        UITK.Button {
            text: i18n.tr("OK")
            color: theme.palette.normal.positive
            enabled: (userAgentName !== "") && ! userAgentNameAlreadyTaken
            onClicked: accept(userAgentName, userAgentString)
        }

        UITK.Button {
            text: i18n.tr("Cancel")
            onClicked: cancel()
        }
    }
}
