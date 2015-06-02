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

Column {
    id: urlsList
    property alias model: urlsListRepeater.model
    property int limit

    signal urlClicked(url url)
    signal urlRemoved(url url)

    spacing: units.gu(1)

    move: Transition { UbuntuNumberAnimation { properties: "x, y" } }

    Repeater {
        id: urlsListRepeater
        property var _currentSwipedItem: null

        delegate: Loader {
            sourceComponent: (index < limit) ? realDelegate : undefined
            Component {
                id: realDelegate
                UrlDelegate{
                    id: urlDelegate
                    width: urlsList.width
                    height: units.gu(5)

                    icon: model.icon
                    title: model.title ? model.title : model.url
                    url: model.url

                    onItemClicked: urlClicked(model.url)

                    property var removalAnimation
                    function remove() {
                        removalAnimation.start()
                    }

                    onSwippingChanged: {
                        urlsListRepeater._updateSwipeState(urlDelegate)
                    }

                    onSwipeStateChanged: {
                        urlsListRepeater._updateSwipeState(urlDelegate)
                    }

                    leftSideAction: Action {
                        iconName: "delete"
                        text: i18n.tr("Delete")
                        onTriggered: {
                            urlDelegate.remove()
                        }
                    }

                    ListView.onRemove: ScriptAction {
                        script: {
                            if (urlsListRepeater._currentSwipedItem === urlDelegate) {
                                urlsListRepeater._currentSwipedItem = null
                            }
                        }
                    }

                    removalAnimation: SequentialAnimation {
                        alwaysRunToEnd: true

                        PropertyAction {
                            target: urlDelegate
                            property: "ListView.delayRemove"
                            value: true
                        }

                        UbuntuNumberAnimation {
                            target: urlDelegate
                            property: "height"
                            to: 0
                        }

                        PropertyAction {
                            target: urlDelegate
                            property: "ListView.delayRemove"
                            value: false
                        }

                        ScriptAction {
                            script: {
                                urlRemoved(model.url)
                            }
                        }
                    }
                }
            }
        }

        function _updateSwipeState(item) {
            if (item.swipping) {
                return
            }

            if (item.swipeState !== "Normal") {
                if (urlsListRepeater._currentSwipedItem !== item) {
                    if (urlsListRepeater._currentSwipedItem) {
                        urlsListRepeater._currentSwipedItem.resetSwipe()
                    }
                    urlsListRepeater._currentSwipedItem = item
                }
            } else if (item.swipeState !== "Normal"
            && urlsListRepeater._currentSwipedItem === item) {
                urlsListRepeater._currentSwipedItem = null
            }
        }
    }
}
