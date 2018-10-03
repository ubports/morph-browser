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
import Ubuntu.Content 1.3
import "MimeTypeMapper.js" as MimeTypeMapper

Item {
    signal exportFromDownloads(var transfer, var mimetypeFilter, bool multiSelect)

    Connections {
        target: ContentHub
        onExportRequested: {
            exportFromDownloads(transfer,
                                MimeTypeMapper.mimeTypeRegexForContentType(transfer.contentType),
                                transfer.selectionType === ContentTransfer.Multiple)
            
        }
    }
}
