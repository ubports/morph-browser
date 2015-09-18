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


function mimeTypeToContentType(mimeType) {
    if(mimeType.search("image/") === 0) {
        return ContentType.Pictures;
    } else if(mimeType.search("audio/") === 0) {
        return ContentType.Music;
    } else if(mimeType.search("video/") === 0) {
        return ContentType.Videos;
    } else if(mimeType.search("text/x-vcard") === 0
              || mimeType.search("text/vcard") === 0) {
        return ContentType.Contacts;
    } else if(mimeType.search("application/epub[+]zip") === 0
              || mimeType.search("application/vnd\.amazon\.ebook") === 0
              || mimeType.search("application/x-mobipocket-ebook") === 0
              || mimeType.search("application/x-fictionbook+xml") === 0
              || mimeType.search("application/x-ms-reader") === 0) {
        return ContentType.EBooks; 
    } else if(mimeType.search("text/") === 0
              || mimeType.search("application/pdf") === 0
              || mimeType.search("application/x-pdf") === 0
              || mimeType.search("application/vnd\.pdf") === 0) {
        return ContentType.Documents;
    } else {
        return ContentType.Unknown;
    }
}

function mimeTypeRegexForContentType(contentType) {
    switch (contentType) {
        case ContentType.Pictures:
            return "image/.*";
        case ContentType.Music:
            return "audio/.*";
        case ContentType.Videos:
            return "video/.*";
        case ContentType.Contacts:
            return "text/x-vcard";
        case ContentType.EBooks:
            return "application/(epub.*|vnd.amazon.ebook|x-mobipocket-ebook|x-fictionbook+xml|x-ms-reader)";
        case ContentType.Documents:
            return "(text/.*|application/pdf|application/x-pdf|application/vnd.pdf)";
        case ContentType.Unknown:
        case ContentType.All:
            return ".*";
    }
}
