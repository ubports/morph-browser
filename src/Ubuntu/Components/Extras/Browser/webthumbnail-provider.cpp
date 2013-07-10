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

#include "webthumbnail-provider.h"
#include "webthumbnail-utils.h"

// Qt
#include <QtCore/QDebug>
#include <QtGui/QImageReader>

WebThumbnailProvider::WebThumbnailProvider(QObject* parent)
    : QObject(parent)
    , QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage WebThumbnailProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    QImage image;
    QFileInfo cached = WebThumbnailUtils::thumbnailFile(QUrl(id));
    if (cached.exists()) {
        QImageReader reader(cached.absoluteFilePath(), "PNG");
        if (requestedSize.isValid()) {
            reader.setScaledSize(requestedSize);
        }
        reader.read(&image);
        if (image.isNull()) {
            qWarning() << "Failed to load cached thumbnail:" << reader.errorString();
        } else {
            *size = image.size();
        }
    }
    return image;
}

bool WebThumbnailProvider::thumbnailExists(const QUrl& url) const
{
    return WebThumbnailUtils::thumbnailFile(url).exists();
}
