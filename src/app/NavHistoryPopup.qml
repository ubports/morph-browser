/*
 * Copyright 2021 UBports Foundation
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
import Ubuntu.Components 1.3
import QtQuick.Controls 2.2 as QQC2

QQC2.Popup {
    id: navHistoryPopup

    property alias model: historyListView.model

    property bool incognito: false
    property real availHeight
    property real availWidth
    property real maximumWidth: units.gu(70)
    property real preferredWidth: availWidth - units.gu(4)

    signal navigate(int offset)

    width: Math.min(preferredWidth, maximumWidth)
    height: scrollView.height
    modal: true
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    function show(caller){
        var mapped = caller.mapToItem(parent, 0, 0)
        x = Qt.binding(function(){
                if (width == maximumWidth) {
                    return mapped.x
                } else {
                    return (availWidth - width) / 2
                }
            })
        y = mapped.y + caller.height
        open()
    }

    onVisibleChanged: {
        if (visible) {
            historyListView.forceActiveFocus()
            historyListView.currentIndex = -1
        }
    }

    ScrollView {
        id: scrollView

        property real maximumHeight: navHistoryPopup.availHeight - units.gu(2)
        property real preferredHeight:  historyListView.contentItem.height

        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }

        height: Math.min(preferredHeight, maximumHeight)

        UbuntuListView {
            id: historyListView

            anchors.fill: parent

            delegate: ListItem {
                id: listItem

                height: layout.height + (divider.visible ? divider.height : 0)
                divider.visible: false

                onClicked: {
                    close()
                    navigate(model.offset)
                }

                MouseArea {
                    id: hover
                    
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    anchors.fill: parent
                }

                Rectangle {
                    id: hoverBg

                    anchors.fill: parent
                    opacity: 0.2
                    visible: hover.containsMouse && !listItem.ListView.isCurrentItem
                    color: theme.palette.normal.focus
                }

                ListItemLayout {
                    id: layout

                    title.text: model.title
                    title.color: theme.palette.normal.foregroundText

                    Favicon {
                        id: favicon
                        
                        source: model.icon
                        SlotsLayout.position: SlotsLayout.Leading;
                        shouldCache: !navHistoryPopup.incognito

                        height: width
                        width: units.gu(2)
                    }
                }
            }
        }
    }
}
