/*
 * Copyright 2014-2015 Canonical Ltd.
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

#include "favicon-fetcher.h"

// Qt
#include <QtCore/QBuffer>
#include <QtCore/QByteArray>
#include <QtCore/QCryptographicHash>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QFileInfo>
#include <QtCore/QMetaObject>
#include <QtCore/QStandardPaths>
#include <QtGui/QImage>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>

#define MAX_REDIRECTIONS 5
#define CACHE_EXPIRATION_DAYS 100

FaviconFetcher::FaviconFetcher(QObject* parent)
    : QObject(parent)
    , m_shouldCache(true)
    , m_reply(0)
    , m_redirections(0)
{
    QDir cacheLocation(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/favicons");
    m_cacheLocation = cacheLocation.absolutePath();
    if (!cacheLocation.exists()) {
        QDir::root().mkpath(m_cacheLocation);
    }
}

FaviconFetcher::~FaviconFetcher()
{
    if (m_reply) {
        m_reply->abort();
        delete m_reply;
    }
}

const QUrl& FaviconFetcher::url() const
{
    return m_url;
}

void FaviconFetcher::setUrl(const QUrl& url)
{
    if (url != m_url) {
        m_url = url;
        Q_EMIT urlChanged();

        setLocalUrl(QUrl());

        if (m_reply) {
            m_reply->abort();
            m_reply = 0;
        }

        if (!url.isValid()) {
            return;
        }

        if (url.isLocalFile()) {
            setLocalUrl(url);
            return;
        }

        QString id = url.toString(QUrl::None);

        QString extension;
        int extensionIndex = id.lastIndexOf(".");
        if (extensionIndex != -1) {
            extension = id.mid(extensionIndex);
        }

        QString hash(QCryptographicHash::hash(id.toUtf8(), QCryptographicHash::Md5).toHex());
        m_filepath = m_cacheLocation + "/" + hash + extension;

        QFileInfo fileinfo(m_filepath);
        if (fileinfo.exists() && (fileinfo.lastModified().daysTo(QDateTime::currentDateTime()) < CACHE_EXPIRATION_DAYS)) {
            setLocalUrl(QUrl::fromLocalFile(m_filepath));
        } else {
            m_redirections = 0;
            download(url);
        }
    }
}

const QUrl& FaviconFetcher::localUrl() const
{
    return m_localUrl;
}

void FaviconFetcher::setLocalUrl(const QUrl& url)
{
    if (url != m_localUrl) {
        m_localUrl = url;
        Q_EMIT localUrlChanged();
    }
}

bool FaviconFetcher::shouldCache() const
{
    return m_shouldCache;
}

void FaviconFetcher::setShouldCache(bool shouldCache)
{
    if (shouldCache != m_shouldCache) {
        m_shouldCache = shouldCache;
        Q_EMIT shouldCacheChanged();
    }
}

const QString& FaviconFetcher::cacheLocation() const
{
    return m_cacheLocation;
}

void FaviconFetcher::download(const QUrl& url)
{
    if (!m_manager) {
        m_manager.reset(new QNetworkAccessManager());
        connect(m_manager.data(), SIGNAL(finished(QNetworkReply*)),
                this, SLOT(downloadFinished(QNetworkReply*)));
    }
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, true);
    // For some reason slashdot.org closes the connection with the default
    // user agent string ("Mozilla/5.0"). Weird.
    request.setHeader(QNetworkRequest::UserAgentHeader, QString("Mozilla"));
    m_reply = m_manager->get(request);
}

void FaviconFetcher::downloadFinished(QNetworkReply* reply)
{
    if (reply->error() == QNetworkReply::OperationCanceledError) {
        reply->deleteLater();
        return;
    }
    QUrl url = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
    if (url.isEmpty()) {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QImage image = QImage::fromData(data);
            if (m_shouldCache && image.save(m_filepath)) {
                setLocalUrl(QUrl::fromLocalFile(m_filepath));
            } else {
                QByteArray ba;
                QBuffer buffer(&ba);
                buffer.open(QIODevice::WriteOnly);
                if (image.save(&buffer, "PNG")) {
                    setLocalUrl(QUrl("data:image/png;base64," + ba.toBase64()));
                }
            }
        } else {
            qWarning() << "Failed to download" << reply->url()
                       << ":" << reply->errorString();
        }
        reply->deleteLater();
        m_reply = 0;
    } else {
        reply->deleteLater();
        m_reply = 0;
        if (++m_redirections < MAX_REDIRECTIONS) {
            QMetaObject::invokeMethod(this, "download",
                                      Qt::QueuedConnection,
                                      Q_ARG(QUrl, url));
        } else {
            qWarning() << "Failed to download" << m_url
                       << ": too many redirections";
        }
    }
}
