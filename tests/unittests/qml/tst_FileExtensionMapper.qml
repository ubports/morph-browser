/*
 * Copyright 2015 Canonical Ltd.
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

import QtTest 1.0
import "../../../src/app/FileExtensionMapper.js" as FileExtensionMapper

TestCase {
    name: "FileExtensionMapper"

    function test_getExtension_data() {
        return [
            {in: "", ext: ""},
            {in: "pdf", ext: ""},
            {in: ".vimrc", ext: ""},
            {in: "example.pdf", ext: "pdf"},
            {in: "http://example.org/path/example.pdf", ext: "pdf"},
            {in: "EXAMPLE.PDF", ext: "pdf"}
        ]
    }

    function test_getExtension(data) {
        compare(FileExtensionMapper.getExtension(data.in), data.ext)
    }

    // Test filenameToMimeType for a few selected extensions
    // (there is no point in testing every single extension).
    function test_filenameToMimeType_data() {
        return [
            {filename: "document.pdf", mimetype: "application/pdf"},
            {filename: "document.ps", mimetype: "application/postscript"},
            {filename: "image.jpg", mimetype: "image/jpeg"},
            {filename: "image.jpeg", mimetype: "image/jpeg"},
            {filename: "image.png", mimetype: "image/png"},
            {filename: "audio.mp3", mimetype: "audio/mpeg"},
            {filename: "playlist.m3u", mimetype: "audio/mpegurl"},
            {filename: "video.avi", mimetype: "video/x-msvideo"},
            {filename: "video.mp4", mimetype: "video/mp4"},
            {filename: "video.mpg", mimetype: "video/mpeg"},
            {filename: "video.mpeg", mimetype: "video/mpeg"},
            {filename: "contact.vcf", mimetype: "text/vcard"},
            {filename: "contact.vcard", mimetype: "text/vcard"},
            {filename: "text.txt", mimetype: "text/plain"},
            {filename: "subtitles.srt", mimetype: "text/plain"},
            {filename: "compressed.zip", mimetype: "application/zip"},
            {filename: "compressed.tar.gz", mimetype: "application/gzip"},
            {filename: "compressed.tgz", mimetype: "application/x-gtar-compressed"},
            {filename: "shared.torrent", mimetype: "application/x-bittorrent"}
        ]
    }

    function test_filenameToMimeType(data) {
        compare(FileExtensionMapper.filenameToMimeType(data.filename), data.mimetype)
    }
}
