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
import Ubuntu.DownloadManager 0.1
import Ubuntu.Content 0.1

Item {
    id: shareItem

    ContentShareDialog {
        id: shareDialog
    }

    Component {
        id: contentItemComponent
        ContentItem { }
    }

    function share(url, name, contentType) {
        shareDialog.contentType = contentType
        shareDialog.items.push(contentItemComponent.createObject(shareItem, {"url" : url, "name" : name}))
        shareDialog.show()
    }

    function shareLink(url, title) {
        share(url, title, ContentType.Links)
    }

}
