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
import Ubuntu.Components 0.1

Rectangle {
    id: topSitesSheet

    property alias bookmarksModel: topSitesView.bookmarksModel
    property alias historyModel: topSitesView.historyModel

    signal bookmarkRequested(url url)
    signal seeMoreBookmarksRequested()
    signal historyEntryRequested(url url)

    TopSitesView {
        id: topSitesView

        anchors.fill: parent

        onBookmarkClicked: topSitesSheet.bookmarkRequested(url)
        onSeeMoreBookmarksClicked: topSitesSheet.seeMoreBookmarksRequested()
        onHistoryEntryClicked: topSitesSheet.historyEntryRequested(url)
    }
}
