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
    property alias model: listview.model

    signal tabSelected(int index)
    signal tabClosed(int index)

    onWheel: wheel.accepted = true

    function reset() {
        listview.positionViewAtBeginning()
    }

    ListView {
        id: listview

        anchors.fill: parent

        spacing: units.gu(-5)
        boundsBehavior: Flickable.StopAtBounds

        delegate: Loader {
            id: delegate
            width: parent.width
            height: tabslist.delegateHeight
            Behavior on height {
                UbuntuNumberAnimation {
                    duration: UbuntuAnimation.BriskDuration
                }
            }

            z: index

            readonly property string title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))

            sourceComponent: (index > 0) ? tabPreviewComponent : currentTabComponent

            Component {
                id: currentTabComponent

                MouseArea {
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    onClicked: {
                        if (mouse.button == Qt.LeftButton) {
                            tabslist.tabSelected(index)
                        }
                    }

                    Rectangle {
                        anchors.fill: tabchrome
                        color: "#312f2c"
                    }

                    TabChrome {
                        id: tabchrome

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                        }

                        title: delegate.title

                        onSelected: tabslist.tabSelected(index)
                        onClosed: tabslist.tabClosed(index)
                    }
                }
            }

            Component {
                id: tabPreviewComponent

                TabPreview {
                    title: delegate.title
                    tab: model.tab

                    onSelected: tabslist.tabSelected(index)
                    onClosed: tabslist.tabClosed(index)
                }
            }
        }
    }
}
