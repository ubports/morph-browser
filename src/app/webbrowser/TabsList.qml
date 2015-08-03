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

Item {
    id: tabslist

    property real delegateHeight
    property real chromeOffset
    property alias model: repeater.model
    readonly property int count: repeater.count

    signal tabSelected(int index)
    signal tabClosed(int index)

    function reset() {
        flickable.contentY = 0
    }

    readonly property bool animating: selectedAnimation.running

    Flickable {
        id: flickable

        anchors.fill: parent

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: width
        contentHeight: model ? (model.count - 1) * delegateHeight + height : 0

        Repeater {
            id: repeater

            delegate: Loader {
                id: delegate

                asynchronous: true

                width: flickable.contentWidth

                height: (index == (repeater.model.count - 1)) ? flickable.height : delegateHeight
                Behavior on height {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                y: Math.max(flickable.contentY, index * delegateHeight)
                Behavior on y {
                    enabled: !flickable.moving && !selectedAnimation.running
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                opacity: selectedAnimation.running && (index > selectedAnimation.index) ? 0 : 1
                Behavior on opacity {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.FastDuration
                    }
                }

                readonly property string title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))

                readonly property bool needsInstance: (index >= 0) && ((flickable.contentY + flickable.height + delegateHeight / 2) >= (index * delegateHeight))
                sourceComponent: needsInstance ? tabPreviewComponent : undefined

                visible: flickable.contentY < ((index + 1) * delegateHeight)

                Component {
                    id: tabPreviewComponent

                    TabPreview {
                        title: delegate.title
                        tab: model.tab
                        showContent: (index > 0) || (delegate.y > flickable.contentY) ||
                                     !(tab.webview && tab.webview.visible)

                        onSelected: tabslist.selectAndAnimateTab(index)
                        onClosed: tabslist.tabClosed(index)
                    }
                }
            }
        }

        PropertyAnimation {
            id: selectedAnimation
            property int index: 0
            target: flickable
            property: "contentY"
            to: index * delegateHeight - chromeOffset
            duration: UbuntuAnimation.FastDuration
            onStopped: tabslist.tabSelected(index)
        }
    }

    function selectAndAnimateTab(index) {
        // Animate tab into full view
        selectedAnimation.index = index
        selectedAnimation.start()
    }
}
