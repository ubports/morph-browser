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

#ifndef __FAVICON_FETCHER_H__
#define __FAVICON_FETCHER_H__

// Qt
#include <QtCore/QScopedPointer>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QtGlobal>
#include <QtCore/QUrl>

class QNetworkAccessManager;
class QNetworkReply;

class FaviconFetcher : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QUrl localUrl READ localUrl NOTIFY localUrlChanged)
    Q_PROPERTY(bool shouldCache READ shouldCache WRITE setShouldCache NOTIFY shouldCacheChanged)

public:
    FaviconFetcher(QObject* parent=0);
    ~FaviconFetcher();

    const QUrl& url() const;
    void setUrl(const QUrl& url);

    const QUrl& localUrl() const;

    bool shouldCache() const;
    void setShouldCache(bool shouldCache);

    const QString& cacheLocation() const;

Q_SIGNALS:
    void urlChanged() const;
    void localUrlChanged() const;
    void shouldCacheChanged() const;

private Q_SLOTS:
    void download(const QUrl& url);
    void downloadFinished(QNetworkReply* reply);

private:
    void setLocalUrl(const QUrl& url);

    bool m_shouldCache;
    QString m_cacheLocation;
    QScopedPointer<QNetworkAccessManager> m_manager;
    QNetworkReply* m_reply;
    QUrl m_url;
    QString m_filepath;
    int m_redirections;
    QUrl m_localUrl;
};

#endif // __FAVICON_FETCHER_H__
