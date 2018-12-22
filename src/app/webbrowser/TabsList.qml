/*
 * Copyright 2014-2016 Canonical Ltd.
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

Item {
    id: tabslist

    property real delegateHeight
    property real chromeHeight
    property alias model: repeater.model
    readonly property int count: repeater.count
    property bool incognito

    signal scheduleTabSwitch(int index)
    signal tabSelected(int index)
    signal tabClosed(int index)

    function reset() {
        flickable.contentY = 0
    }

    readonly property bool animating: selectedAnimation.running

    TabChrome {
        id: invisibleTabChrome
        visible: false
    }

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: invisibleTabChrome.height
        color: theme.palette.normal.backgroundText
    }

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
                readonly property string icon: model.icon

                active: (index >= 0) && ((flickable.contentY + flickable.height + delegateHeight / 2) >= (index * delegateHeight))

                visible: flickable.contentY < ((index + 1) * delegateHeight)

                sourceComponent: TabPreview {
                    title: delegate.title
                    icon: delegate.icon
                    incognito: tabslist.incognito
                    tab: model.tab
                    showContent: ((index > 0) && (delegate.y > flickable.contentY)) ||
                                 !(tab && tab.webview && tab.webview.visible)

                  /*  Binding {
                        // Change the height of the location bar controller
                        // for the first webview only, and only while the tabs
                        // list view is visible.
                        when: tabslist.visible && (index == 0)
                        target: tab && tab.webview ? tab.webview.locationBarController : null
                        property: "height"
                        value: invisibleTabChrome.height
                    } */

                    onSelected: tabslist.selectAndAnimateTab(index)
                    onClosed: tabslist.tabClosed(index)
                }
            }
        }

        PropertyAnimation {
            id: selectedAnimation
            property int index: 0
            target: flickable
            property: "contentY"
            to: index * delegateHeight - chromeHeight + invisibleTabChrome.height
            duration: UbuntuAnimation.FastDuration
            onStopped: {
                // Delay switching the tab until after the animation has completed.
                delayedTabSelection.index = index
                delayedTabSelection.start()
            }
        }

        Timer {
            id: delayedTabSelection
            interval: 1
            property int index: 0
            onTriggered: tabslist.tabSelected(index)
        }
    }

    function selectAndAnimateTab(index) {
        // Animate tab into full view
        if (index == 0) {
            tabSelected(0)
        } else {
            selectedAnimation.index = index
            scheduleTabSwitch(index)
            selectedAnimation.start()
        }
    }
}
