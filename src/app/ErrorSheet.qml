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

import QtQuick 2.4
import Ubuntu.Components 1.3

Rectangle {
    property string url

    signal refreshClicked()

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(4)

        spacing: units.gu(3)

        Label {
            width: parent.width
            fontSize: "x-large"
            text: i18n.tr("Network Error")
        }

        Label {
            width: parent.width
            // TRANSLATORS: %1 refers to the URL of the current page
            text: i18n.tr("It appears you are having trouble viewing: %1.").arg(url)
            wrapMode: Text.Wrap
        }

        Label {
            width: parent.width
            text: i18n.tr("Please check your network settings and try refreshing the page.")
            wrapMode: Text.Wrap
        }

        Button {
            text: i18n.tr("Refresh page")
            onClicked: refreshClicked()
        }
    }
}
