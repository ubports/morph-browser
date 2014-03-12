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

#ifndef __WEBTHUMBNAIL_PROVIDER_H__
#define __WEBTHUMBNAIL_PROVIDER_H__

// Qt
#include <QtCore/QObject>
#include <QtCore/QUrl>
#include <QtQuick/QQuickImageProvider>

class WebThumbnailProvider : public QObject, public QQuickImageProvider
{
    Q_OBJECT

public:
    WebThumbnailProvider(QObject* parent=0);

    virtual QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize);

    Q_INVOKABLE bool thumbnailExists(const QUrl& url) const;
};

#endif // __WEBTHUMBNAIL_PROVIDER_H__
