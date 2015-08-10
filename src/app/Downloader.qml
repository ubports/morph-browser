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
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.DownloadManager 0.1
import Ubuntu.Content 0.1
import "MimeTypeMapper.js" as MimeTypeMapper
import "FileExtensionMapper.js" as FileExtensionMapper

Item {
    id: downloadItem

    property string mimeType;

    Component {
        id: downloadDialog
        ContentDownloadDialog { }
    }

    Component {
        id: metadataComponent
        Metadata {
            showInIndicator: true
        }
    }

    Component {
        id: downloadComponent
        SingleDownload {
            id: downloader
            autoStart: false
            property var contentType
            property string url
            property bool moveToDownloads: false
            // DownloadId gets cleared when finished, but we still need a
            // copy to identify the download we've just finished in the database
            property string currentDownloadId
            onDownloadIdChanged: {
                currentDownloadId = downloadId;
                browser.downloadsModel.add(downloadId, url, downloadItem.mimeType)
                PopupUtils.open(downloadDialog, downloadItem, {"contentType" : contentType, "downloadId" : downloadId, "singleDownload" : downloader})
            }

            onProgressChanged: {
                browser.downloadsModel.setProgress(downloadId, progress)
            }

            onErrorChanged: {
                browser.downloadsModel.setError(downloadId, error)
            }

            onFinished: {
                if (moveToDownloads) {
                    browser.downloadsModel.moveToDownloads(currentDownloadId, path)
                } else {
                    browser.downloadsModel.setPath(currentDownloadId, path)
                }
                browser.downloadsModel.setComplete(currentDownloadId, true)
                metadata.destroy()
                destroy()
            }
        }
    }

    function download(url, contentType, headers, metadata) {
        var singleDownload = downloadComponent.createObject(downloadItem)
        singleDownload.contentType = contentType
        if (headers) { 
            singleDownload.headers = headers
        }
        singleDownload.metadata = metadata
        singleDownload.url = url
        singleDownload.download(url)
    }

    function downloadPicture(url, headers) {
        var metadata = metadataComponent.createObject(downloadItem)
        downloadItem.mimeType = "image/*"
        download(url, ContentType.Pictures, headers, metadata)
    }

    function downloadMimeType(url, mimeType, headers, filename) {
        var metadata = metadataComponent.createObject(downloadItem)
        var contentType = MimeTypeMapper.mimeTypeToContentType(mimeType)
        if (contentType == ContentType.Unknown && filename) {
            // If we can't determine the content type from the mime-type
            // attempt to discover it from the file extension
            contentType = FileExtensionMapper.filenameToContentType(filename)
        }
        if (mimeType == "application/zip" && is7digital(url)) {
            // This is problably an album download from 7digital (although we 
            // can't be 100% certain). 7digital albums are served as a zip
            // so we let download manager extract the zip and send its contents
            // on to the selected application via content-hub
            contentType = ContentType.Music
            metadata.extract = true
        }
        metadata.title = filename
        downloadItem.mimeType = mimeType
        download(url, contentType, headers, metadata)
    }

    function is7digital(url) {
        return url.toString().search(/[^\/]+:\/\/[^\/]*7digital.com\//) !== -1
    }

}
