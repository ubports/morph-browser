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
import Ubuntu.Components 1.1

ListView {
    id: tabslist

    property real delegateHeight

    signal tabSelected(int index)
    signal closeRequested(int index)

    spacing: units.gu(-5)
    boundsBehavior: Flickable.StopAtBounds

    delegate: TabPreview {
        width: parent.width
        height: tabslist.delegateHeight
        Behavior on height {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.BriskDuration
            }
        }

        z: index

        title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
        tab: model.tab

        onSelected: tabslist.tabSelected(index)
        onCloseRequested: tabslist.closeRequested(index)
    }
}
