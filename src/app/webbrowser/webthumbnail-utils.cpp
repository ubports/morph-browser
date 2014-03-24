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

#include "domain-utils.h"
#include "webthumbnail-utils.h"

// Qt
#include <QtCore/QCryptographicHash>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QUrl>
#include <QtGui/QImage>

#define MAX_CACHE_SIZE_IN_BYTES 5 * 1024 * 1024 // 5MB

WebThumbnailUtils::WebThumbnailUtils(QObject* parent)
    : QObject(parent)
{
}

WebThumbnailUtils& WebThumbnailUtils::instance()
{
    static WebThumbnailUtils utils;
    return utils;
}

WebThumbnailUtils::~WebThumbnailUtils()
{
}

QDir WebThumbnailUtils::cacheLocation()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
}

void WebThumbnailUtils::ensureCacheLocation()
{
    QDir cache = cacheLocation();
    if (!cache.exists()) {
        QDir::root().mkpath(cache.absolutePath());
    }
}

QFileInfo WebThumbnailUtils::thumbnailFile(const QUrl& url)
{
    QString hash(QCryptographicHash::hash(url.toEncoded(), QCryptographicHash::Md5).toHex());
    return cacheLocation().absoluteFilePath(hash + ".png");
}

void WebThumbnailUtils::cacheThumbnail(const QUrl& url, const QImage& thumbnail) const
{
    ensureCacheLocation();
    QFileInfo file = thumbnailFile(url);
    bool saved = thumbnail.save(file.absoluteFilePath());

    if (saved) {
        // Make a link to the thumbnail file for the corresponding domain’s thumbnail.
        QUrl domain(DomainUtils::extractTopLevelDomainName(url));
        QString domainThumbnail = WebThumbnailUtils::thumbnailFile(domain).absoluteFilePath();
        if (QFile::exists(domainThumbnail)) {
            QFile::remove(domainThumbnail);
        }
        QFile::link(file.fileName(), domainThumbnail);
    }

    expireCache();
}

void WebThumbnailUtils::expireCache() const
{
    QDir cache = cacheLocation();
    if (!cache.exists()) {
        return;
    }
    QStringList nameFilters = QStringList() << "*.png";
    QDir::Filters filters = QDir::Files | QDir::NoDotAndDotDot;
    QDir::SortFlags sort = QDir::Time;
    QFileInfoList entries = cache.entryInfoList(nameFilters, filters, sort);
    qint64 currentSize = 0;
    Q_FOREACH(const QFileInfo& entry, entries) {
        currentSize += entry.size();
    }
    if (currentSize > MAX_CACHE_SIZE_IN_BYTES) {
        qint64 goal = MAX_CACHE_SIZE_IN_BYTES * 9 / 10;
        while (!entries.isEmpty() && (currentSize > goal)) {
            QFileInfo entry = entries.takeLast();
            qint64 size = entry.size();
            if (QFile::remove(entry.absoluteFilePath())) {
                currentSize -= size;
            }
        }
    }
}
