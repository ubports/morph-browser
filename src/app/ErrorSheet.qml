/*
 * Copyright 2013-2015 Canonical Ltd.
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
import QtWebEngine 1.7

Rectangle {
    property string url
    property string errorString
    property int errorDomain
    property bool canGoBack
    color: theme.palette.normal.background

    signal backToSafetyClicked()
    signal refreshClicked()

    Column {
        anchors.fill: parent
        anchors.margins: units.gu(4)

        spacing: units.gu(3)

        Label {
            width: parent.width
            fontSize: "x-large"
            text: (errorDomain === WebEngineView.CertificateErrorDomain) ? i18n.tr("Certificate Error") : i18n.tr("Network Error")
            color: theme.palette.normal.overlayText
        }

        Label {
            width: parent.width
            // TRANSLATORS: %1 refers to the URL of the current page
            text: i18n.tr("It appears you are having trouble viewing: %1.").arg(url)
            wrapMode: Text.Wrap
            color: theme.palette.normal.overlayText
        }

        Label {
            width: parent.width
            text: i18n.tr("Error: %1".arg(errorString))
            visible: errorString !== ""
            color: theme.palette.normal.overlayText
        }

        Button {
            text: i18n.tr("Back to safety")
            color: theme.palette.normal.positive
            visible: canGoBack && (errorDomain === WebEngineView.CertificateErrorDomain)
            onClicked: backToSafetyClicked()
        }

        Label {
            width: parent.width
            text: i18n.tr("Please check your network settings and try refreshing the page.")
            wrapMode: Text.Wrap
            visible: (errorDomain !== WebEngineView.CertificateErrorDomain)
            color: theme.palette.normal.overlayText
        }

        Button {
            text: i18n.tr("Refresh page")
            onClicked: refreshClicked()
        }
    }
}
