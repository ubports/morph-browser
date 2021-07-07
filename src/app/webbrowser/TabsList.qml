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
import QtQml.Models 2.2

Item {
    id: tabslist

    property real delegateHeight
    property real chromeHeight
    property real tabChromeHeight: units.gu(5)
    property alias model: filteredModel.model
    readonly property int count: model.count
    property alias searchText: searchField.text
    property alias view: list.item
    property bool incognito
    property bool searchMode: false

    signal scheduleTabSwitch(int index)
    signal tabSelected(int index)
    signal tabClosed(int index)

    function reset() {
        tabslist.view.contentY = 0
        searchText = ""
    }

    readonly property bool animating: selectedAnimation.running

    Connections {
        // WORKAROUND: Repeater items in listNarrowComponent stay hidden when switching from wide to narrow layout
        // if the model is direcly assigned in its definition. This solves that issue.
        target: browser
        onWideChanged: if (!target.wide) searchText = " "
    }

    TabChrome {
        id: invisibleTabChrome
        visible: false
    }

    Rectangle {
        id: backrect
        width: parent.width
        height: delayBackground.running ? invisibleTabChrome.height : parent.height
        color: theme.palette.normal.base
        visible: !browser.wide
    }
    onVisibleChanged: {
        if (visible) {
            delayBackground.start()

            if (browser.wide) {
                searchMode = true
            } else {
                searchMode = false
            }
        } else {
            if (browser.wide) {
                tabslist.view.focus = false
            }
        }
    }

    Timer {
        id: delayBackground
        interval: 300
    }

    function focusInput() {
        searchMode = true
        searchField.selectAll();
        searchField.forceActiveFocus()
    }

    function selectFirstItem() {
        var firstItem = matchGroup.get(0)
        if (browser.wide) {
            tabslist.tabSelected(firstItem.itemsIndex)
        } else {
            tabslist.selectAndAnimateTab(firstItem.itemsIndex, firstItem.index)
        }
    }

    Loader {
        id: dragLoader

        readonly property real dragThreshold: units.gu(15)

        active: tabslist.view && !browser.wide
        asynchronous: true
        sourceComponent: Connections{
            target: tabslist.view

            onVerticalOvershootChanged: {
                if(target.verticalOvershoot < 0 && target.dragging){
                    if(-target.verticalOvershoot >= dragThreshold){
                        tabslist.searchMode = true
                        tabslist.focusInput()
                    }
                }
            }
        }
    }  

    Rectangle {
        id: searchRec

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        height: units.gu(6)
        color: browser.wide ? "transparent" : theme.palette.normal.background
        opacity: tabslist.searchMode ? 1 : tabslist.view.verticalOvershoot < 0 ? -tabslist.view.verticalOvershoot / dragLoader.dragThreshold : 0
        Behavior on opacity {
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.FastDuration
            }
        }

        TextField {
            id: searchField

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }
            placeholderText: i18n.tr("Search Tabs")
            inputMethodHints: Qt.ImhNoPredictiveText
            primaryItem: Icon {
                height: parent.height * 0.5
                width: height
                name: "search"
            }

            KeyNavigation.down: tabslist.view
            onTextChanged: searchDelay.restart()
            onAccepted: tabslist.selectFirstItem()

            Timer {
                id: searchDelay
                interval: 300
                onTriggered: filteredModel.update(searchField.text)
            }
        }
    }

   Label {
        id: resultsLabel

        text: searchDelay.running ? i18n.tr("Loading...") : i18n.tr("No results")
        textSize: Label.Large
        font.weight: Font.DemiBold
        color: browser.wide ? UbuntuColors.porcelain : theme.palette.normal.baseText
        anchors {
            top: searchRec.bottom
            horizontalCenter: parent.horizontalCenter
            margins: units.gu(3)
        }
        visible: filteredModel.count == 0
    }

    Loader {
        id: list

        asynchronous: true
        anchors.fill: parent
        anchors.topMargin: tabslist.searchMode ? searchRec.height : 0
        sourceComponent: browser.wide ? listWideComponent : listNarrowComponent

        Behavior on anchors.topMargin {
            enabled: !browser.wide
            UbuntuNumberAnimation {
                duration: UbuntuAnimation.SnapDuration
            }
        }
    }

    DelegateModel {
        id: filteredModel

        function update(searchText) {
            if (items.count > 0) {
                items.setGroups(0, items.count, ["items"]);
            }

            if (searchText) {
                filterOnGroup = "match"
                var match = [];
                var searchTextUpper = searchText.toUpperCase()
                var titleUpper
                var urlUpper
                var item

                for (var i = 0; i < items.count; ++i) {
                    item = items.get(i);
                    titleUpper = item.model.title.toUpperCase()
                    urlUpper = item.model.url.toString().toUpperCase()

                    if (titleUpper.indexOf(searchTextUpper) > -1 || urlUpper.indexOf(searchTextUpper) > -1 ) {
                        match.push(item);
                    }
                }

                for (i = 0; i < match.length; ++i) {
                    item = match[i];
                    item.inMatch = true;
                }
            } else {
                filterOnGroup = "items"
            }
        }

        groups: [
            DelegateModelGroup {
                id: matchGroup

                name: "match"
                includeByDefault: false
            }
        ]

        delegate: Package {
            id: packageDelegate

            Item {
                id: gridDelegate

                Package.name: "grid"

                property int tabIndex: index

                width: tabslist.view.cellWidth
                height: tabslist.view.cellHeight
                clip: true
                
                TabPreview {
                    property real horizontalMargin: units.gu(1)
                    property real verticalMargin: horizontalMargin * ((gridDelegate.height - tabslist.tabChromeHeight) / gridDelegate.width)

                    title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                    tabIcon: model.icon
                    incognito: tabslist.incognito
                    tab: model.tab
                    chromeHeight: tabslist.tabChromeHeight

                    anchors {
                        fill: parent
                        leftMargin: horizontalMargin
                        rightMargin: horizontalMargin
                        topMargin: verticalMargin
                        bottomMargin: verticalMargin
                    }
                    
                    onSelected: tabslist.tabSelected(index)
                    onClosed: tabslist.tabClosed(index)
                }
            }

            Loader {
                id: listDelegate

                property int groupIndex: filteredModel.filterOnGroup === "match" ? packageDelegate.DelegateModel.matchIndex : index
                readonly property string title: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                readonly property string icon: model.icon

                Package.name: "list"

                asynchronous: true
                width: tabslist.view.contentWidth
                height: tabslist.view.height + (tabslist.searchMode ? searchRec.height : 0)
                opacity: selectedAnimation.running && (groupIndex > selectedAnimation.listIndex) ? 0 : 1
                Behavior on opacity {
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.FastDuration
                    }
                }
                y: Math.max(tabslist.view.contentY, groupIndex * delegateHeight)
                Behavior on y {
                    enabled: !tabslist.view.moving && !selectedAnimation.running
                    UbuntuNumberAnimation {
                        duration: UbuntuAnimation.BriskDuration
                    }
                }

                active: (groupIndex >= 0) && ((tabslist.view.contentY + tabslist.view.height + delegateHeight / 2) >= (groupIndex * delegateHeight))
                visible: tabslist.view.contentY < ((groupIndex + 1) * delegateHeight)

                sourceComponent: TabPreview {
                    title: listDelegate.title
                    tabIcon: listDelegate.icon
                    incognito: tabslist.incognito
                    tab: model.tab
                    chromeHeight: tabslist.tabChromeHeight

                  /*  Binding {
                        // Change the height of the location bar controller
                        // for the first webview only, and only while the tabs
                        // list view is visible.
                        when: tabslist.visible && (index == 0)
                        target: tab && tab.webview ? tab.webview.locationBarController : null
                        property: "height"
                        value: invisibleTabChrome.height
                    } */

                    onSelected: tabslist.selectAndAnimateTab(index, groupIndex)
                    onClosed: tabslist.tabClosed(index)
                }
            }
        }
    }

    Component {
        id: listWideComponent

        GridView {
            id: gridView

            property int columnCount: switch (true) {
                case tabslist.width >= units.gu(100):
                    3
                    break;
                case tabslist.width >= units.gu(60):
                    2
                    break;
                default:
                    1
                    break;
            }

            clip: true
            model: filteredModel.parts.grid
            cellWidth: (tabslist.width) / columnCount
            cellHeight: ((cellWidth * (browser.height - tabslist.chromeHeight)) / browser.width) + tabslist.tabChromeHeight
            highlight: Component {
                Item {
                    z: 10
                    width: gridView.cellWidth
                    height: gridView.cellHeight
                    opacity: 0.4
                    visible: gridView.activeFocus

                    Rectangle {
                        anchors.fill: parent
                        color: theme.palette.normal.focus
                    }
                }
            }

            Keys.onEnterPressed: tabslist.tabSelected(currentItem.tabIndex)
            Keys.onReturnPressed: tabslist.tabSelected(currentItem.tabIndex)
        }
    }

    Component {
        id: listNarrowComponent

        Flickable {
            id: flickable

            anchors.fill: parent

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragOverBounds
            contentWidth: width
            contentHeight: filteredModel ? (filteredModel.count - 1) * delegateHeight + height : 0

            Repeater {
                id: repeater

                model: filteredModel.parts.list
            }
        }
    }

    Timer {
        id: delayedTabSelection
        interval: 1
        property int index: 0
        onTriggered: tabslist.tabSelected(index)
    }

    PropertyAnimation {
        id: selectedAnimation
        property int tabIndex: 0
        property int listIndex: 0
        target: tabslist.view
        property: "contentY"
        to: listIndex * delegateHeight
        duration: UbuntuAnimation.FastDuration
        onStopped: {
            // Delay switching the tab until after the animation has completed.
            delayedTabSelection.index = tabIndex
            delayedTabSelection.start()
        }
    }

    function selectAndAnimateTab(tabIndex, listIndex) {
        if (tabIndex == 0) {
            tabSelected(0)
        } else {
            selectedAnimation.tabIndex = tabIndex
            selectedAnimation.listIndex = listIndex ? listIndex : tabIndex
            scheduleTabSwitch(tabIndex)
            selectedAnimation.start()
        }
    }
}
