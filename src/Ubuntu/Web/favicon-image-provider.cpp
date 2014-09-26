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

#include "favicon-image-provider.h"

// Qt
#include <QtCore/QCryptographicHash>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QEventLoop>
#include <QtCore/QFileInfo>
#include <QtCore/QStandardPaths>
#include <QtCore/QUrl>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>

#define MAX_REDIRECTIONS 5
#define CACHE_EXPIRATION_DAYS 100

FaviconImageProvider::FaviconImageProvider()
    : QQuickImageProvider(QQmlImageProviderBase::Image, QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    QDir cacheLocation(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/favicons");
    m_cacheLocation = cacheLocation.absolutePath();
    if (!cacheLocation.exists()) {
        QDir::root().mkpath(m_cacheLocation);
    }
}

QImage FaviconImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    if (id.isEmpty()) {
        return QImage();
    }

    QString extension;
    int extensionIndex = id.lastIndexOf(".");
    if (extensionIndex != -1) {
        extension = id.mid(extensionIndex);
    }
    QString hash(QCryptographicHash::hash(id.toUtf8(), QCryptographicHash::Md5).toHex());
    QString filepath = m_cacheLocation + "/" + hash + extension;

    QImage image;
    QFileInfo fileinfo(filepath);
    if (fileinfo.exists()) {
        if (fileinfo.lastModified().daysTo(QDateTime::currentDateTime()) > CACHE_EXPIRATION_DAYS) {
            image = downloadImage(id);
            if (!image.isNull()) {
                image.save(filepath);
            }
        } else {
            image.load(filepath);
        }
    } else {
        image = downloadImage(id);
        if (!image.isNull()) {
            image.save(filepath);
        }
    }

    *size = image.size();
    if (!image.isNull() && requestedSize.isValid() && (image.size() != requestedSize)) {
        return image.scaled(requestedSize, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    } else {
        return image;
    }
}

QImage FaviconImageProvider::downloadImage(const QUrl& url)
{
    if (!m_manager) {
        m_manager.reset(new QNetworkAccessManager());
    }
    QUrl currentUrl(url);
    int redirections = 0;
    while (redirections < MAX_REDIRECTIONS) {
        QNetworkRequest request(currentUrl);
        request.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, true);
        QNetworkReply* reply = m_manager->get(request);
        QEventLoop loop;
        QObject::connect(reply, SIGNAL(finished()), &loop, SLOT(quit()));
        loop.exec();
        currentUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
        if (currentUrl.isEmpty()) {
            if (reply->error() != QNetworkReply::NoError) {
                qWarning() << "Failed to download" << url << ":" << reply->errorString();
                delete reply;
                return QImage();
            } else {
                QByteArray data = reply->readAll();
                delete reply;
                return QImage::fromData(data);
            }
        } else {
            delete reply;
            ++redirections;
        }
    }
    qWarning() << "Failed to download" << url << ": too many redirections";
    return QImage();
}
