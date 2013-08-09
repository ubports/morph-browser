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
#include <QtCore/QObject>

class QImage;
class QUrl;

class WebThumbnailUtils : public QObject
{
    Q_OBJECT

public:
    static WebThumbnailUtils& instance();
    ~WebThumbnailUtils();

    static QDir cacheLocation();
    static void ensureCacheLocation();
    static QFileInfo thumbnailFile(const QUrl& url);

public Q_SLOTS:
    void cacheThumbnail(const QUrl& url, const QImage& thumbnail) const;

private:
    WebThumbnailUtils(QObject* parent=0);

    void expireCache() const;
};

#endif // __WEBTHUMBNAIL_UTILS_H__
