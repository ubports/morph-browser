/*
 * Copyright 2013 Canonical Ltd.
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

#ifndef __WEBTHUMBNAIL_UTILS_H__
#define __WEBTHUMBNAIL_UTILS_H__

// Qt
#include <QtCore/QDir>
#include <QtCore/QFileInfo>

class QImage;
class QUrl;

class WebThumbnailUtils
{
public:
    static QDir cacheLocation();
    static void ensureCacheLocation();
    static QFileInfo thumbnailFile(const QUrl& url);
    static bool cacheThumbnail(const QUrl& url, const QImage& thumbnail);
    static void expireCache();
};

#endif // __WEBTHUMBNAIL_UTILS_H__
