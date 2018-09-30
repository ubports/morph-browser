/*
 * Copyright 2015 Canonical Ltd.
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
import Ubuntu.Components.ListItems 1.3 as ListItems
import Ubuntu.Components.Popups 1.3 as Popups
import QtWebEngine 1.5

Popups.Dialog {
    id: contextMenu

    //property QtObject contextModel: model
    property ActionList actions: null
    property var titleContent

    QtObject {
        id: internal
        readonly property bool isImage: false //(contextModel.mediaType === Oxide.WebView.MediaTypeImage) ||
                                        //(contextModel.mediaType === Oxide.WebView.MediaTypeCanvas)
    }

    Row {
        id: header
        spacing: units.gu(2)
        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }
        height: units.gu(2 * title.lineCount + 3)
        visible: title.text

        Icon {
            width: units.gu(2)
            height: units.gu(2)
            anchors {
                top: parent.top
                topMargin: units.gu(2)
            }
            name: internal.isImage ? "stock_image" : ""
            // work around the lack of a standard stock_link symbolic icon in the theme
            Component.onCompleted: {
                if (!name) {
                    source = "assets/stock_link.svg"
                }
            }
        }

        Label {
            id: title
            objectName: "titleLabel"
            text: titleContent
            //text: contextModel.srcUrl.toString() ? contextModel.srcUrl : contextModel.linkUrl
            width: parent.width - units.gu(4)
            anchors {
                top: parent.top
                topMargin: units.gu(2)
                bottom: parent.bottom
            }
            fontSize: "x-small"
            maximumLineCount: 2
            wrapMode: Text.Wrap
            height: contentHeight
        }
    }

    ListItems.ThinDivider {
        anchors {
            left: parent.left
            leftMargin: units.gu(2)
            right: parent.right
            rightMargin: units.gu(2)
        }
        visible: header.visible
    }

    Repeater {
        model: actions.children
        delegate: ListItems.Empty {
            action: modelData
            objectName: action.objectName + "_item"
            visible: action.enabled
            showDivider: false

            height: units.gu(5)

            Label {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                    verticalCenter: parent.verticalCenter
                }
                fontSize: "x-small"
                text: action.text
            }

            ListItems.ThinDivider {
                anchors {
                    left: parent.left
                    leftMargin: units.gu(2)
                    right: parent.right
                    rightMargin: units.gu(2)
                    bottom: parent.bottom
                }
            }

            onTriggered: contextMenu.hide()
        }
    }

    ListItems.Empty {
        objectName: "cancelAction"
        height: units.gu(5)
        showDivider: false
        Label {
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                right: parent.right
                rightMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            fontSize: "x-small"
            text: i18n.tr("Cancel")
        }
        onTriggered: contextMenu.hide()
    }
    
    /*
    onVisibleChanged: {
        if (!visible) {
            contextModel.close()
        }
    }
    */

    // adjust default dialog visuals to custom requirements for the context menu
    Binding {
        target: __foreground
        property: "margins"
        value: 0
    }
    Binding {
        target: __foreground
        property: "itemSpacing"
        value: 0
    }

    // We can’t prevent the dialog from stealing the focus from
    // the webview, but we can at least restore it when the
    // dialog is closed (https://launchpad.net/bugs/1526884).
    //Component.onDestruction: Oxide.WebView.view.forceActiveFocus()
}
