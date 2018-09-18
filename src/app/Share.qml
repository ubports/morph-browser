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
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.3

Item {
    id: shareItem

    signal done()

    Component {
        id: shareDialog
        ContentShareDialog {
            Component.onDestruction: shareItem.done()
        }
    }

    Component {
        id: contentItemComponent
        ContentItem {}
    }

    QtObject {
        id: internal

        function share(url, text, contentType) {
            var sharePopup = PopupUtils.open(shareDialog, shareItem, {"contentType" : contentType})
            sharePopup.items.push(contentItemComponent.createObject(shareItem, {"url" : url, "text": text}))
        }
    }

    function shareLink(url, title) {
        internal.share(url, title, ContentType.Links)
    }

    function shareText(text) {
        internal.share("", text, ContentType.Text)
    }
}
