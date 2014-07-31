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

#ifndef __FAVICON_IMAGE_PROVIDER_H__
#define __FAVICON_IMAGE_PROVIDER_H__

// Qt
#include <QtCore/QScopedPointer>
#include <QtCore/QString>
#include <QtCore/QtGlobal>
#include <QtQuick/QQuickImageProvider>

class QNetworkAccessManager;
class QUrl;

class FaviconImageProvider Q_DECL_FINAL : public QQuickImageProvider
{
public:
    FaviconImageProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize);

private:
    QImage downloadImage(const QUrl& url);

    QString m_cacheLocation;
    QScopedPointer<QNetworkAccessManager> m_manager;
};

#endif // __FAVICON_IMAGE_PROVIDER_H__
