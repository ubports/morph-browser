/*
 * Copyright 2019 ubports
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
import QtWebEngine 1.5
import Morph.Web 0.1
import ".." as Common

FocusScope {
    id: settingsItem

    property QtObject settingsObject

    signal done()
 
    Common.BrowserPage {
        title: i18n.tr("WebappContainer Settings")

        anchors.fill: parent
        focus: true

        onBack: settingsItem.done()

        Flickable {
            anchors.fill: parent
            contentHeight: settingsCol.height

            Column {
                id: settingsCol

                width: parent.width
 
                ListItem {
                    objectName: "DomainSettings"

                    ListItemLayout {
                       title.text: "Domain specific settings"
                       ProgressionSlot {}
                   }

                   onClicked: domainSettingsViewLoader.active = true
                }
            }
        }
    }

    Loader {
        id: domainSettingsViewLoader

        anchors.fill: parent
        active: false
        asynchronous: true
        Component.onCompleted: {
            setSource("../DomainSettingsPage.qml")
        }

        Connections {
            target: domainSettingsViewLoader.item
            onDone: domainSettingsViewLoader.active = false
        }
    }
}
