/*
 * Copyright 2014-2015 Canonical Ltd.
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

MouseArea {
    id: tabslist

    property real delegateHeight
    property alias model: repeater.model
    readonly property int count: repeater.count

    signal tabSelected(int index)
    signal tabClosed(int index)

    onWheel: wheel.accepted = true

    function reset() {
        flickable.contentY = 0
    }

    Flickable {
        id: flickable

        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: width
        contentHeight: (model.count - 1) * delegateHeight / 2 + height

        Repeater {
            id: repeater

            width: flickable.contentWidth
            height: flickable.contentHeight

            delegate: Loader {
                id: delegate

                asynchronous: true

                width: repeater.width

                height: (index == (repeater.model.count - 1)) ? flickable.height : delegateHeight
                Behavior on height {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                y: Math.max(flickable.contentY, (index * delegateHeight) - flickable.contentY)
                Behavior on y {
                    enabled: !flickable.moving
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                readonly property string title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))

                readonly property bool needsInstance: (index >= 0) && ((flickable.contentY + flickable.height + delegateHeight / 2) >= (index * delegateHeight))
                sourceComponent: needsInstance ? tabPreviewComponent : undefined

                Component {
                    id: tabPreviewComponent

                    TabPreview {
                        title: delegate.title
                        tab: model.tab
                        showContent: index > 0

                        onSelected: tabslist.tabSelected(index)
                        onClosed: tabslist.tabClosed(index)
                    }
                }
            }
        }
    }
}
