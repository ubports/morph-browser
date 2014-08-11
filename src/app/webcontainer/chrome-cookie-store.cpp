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

#include "chrome-cookie-store.h"

#include <QDebug>
#include <QFileInfo>
#include <QStandardPaths>
#include <QMetaMethod>

static qint64 dateTimeToChrome(const QDateTime &time)
{
    /* Chrome uses Mon Jan 01 00:00:00 UTC 1601 as the epoch, hence the
     * magic number */
    return (time.toMSecsSinceEpoch() + 11644473600000) * 1000;
}

static QDateTime dateTimeFromChrome(qint64 chromeTimeStamp)
{
    qint64 msecsSinceEpoch = chromeTimeStamp / 1000 - 11644473600000;
    return QDateTime::fromMSecsSinceEpoch(msecsSinceEpoch);
}

ChromeCookieStore::ChromeCookieStore(QObject* parent):
    CookieStore(parent), m_backend(0)
{}

void ChromeCookieStore::setOxideStoreBackend(QObject* backend)
{
    if (m_backend == backend)
        return;

    m_backend = backend;

    emit oxideStoreBackendChanged();
}

QObject* ChromeCookieStore::oxideStoreBackend() const
{
    return m_backend;
}

void ChromeCookieStore::cookiesReceived(const Cookies& cookies)
{
    emit gotCookies(cookies);
}

void ChromeCookieStore::cookiesUpdated(bool status)
{
    emit cookiesSet(status);
}

void ChromeCookieStore::doGetCookies()
{
    if ( ! m_backend)
        return;

    QByteArray normalizedSignature =
      QMetaObject::normalizedSignature("gotCookies(int, const QVariant&, RequestStatus)");
    int idx = m_backend->metaObject()->indexOfSignal(normalizedSignature);
    if (idx != -1) {
      QMetaMethod method = m_backend->metaObject()->method(idx);
      connect(m_backend, method,
              this, metaObject()->method(
                        metaObject()->indexOfSlot(
                            "cookiesReceived(const QList<QNetworkCookie>&)")));
    }

    normalizedSignature = QMetaObject::normalizedSignature("getAllCookies()");
    idx = m_backend->metaObject()->indexOfMethod(normalizedSignature);
    if (idx != -1) {
        QMetaMethod method = m_backend->metaObject()->method(idx);
        method.invoke(m_backend, Qt::DirectConnection);
    }
}

QDateTime ChromeCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(m_dbPath);
    return dbFileInfo.lastModified();
}

void ChromeCookieStore::doSetCookies(const Cookies& cookies)
{
    if ( ! m_backend)
        return;

    QByteArray normalizedSignature =
      QMetaObject::normalizedSignature("cookiesSet(bool, RequestStatus)");
    int idx = m_backend->metaObject()->indexOfSignal(normalizedSignature);
    if (idx != -1) {
      QMetaMethod method = m_backend->metaObject()->method(idx);
      connect(m_backend, method, this, metaObject()->method(metaObject()->indexOfSlot("cookiesUpdates(bool)")));
    }

    normalizedSignature = QMetaObject::normalizedSignature("setCookies(const QList<QNetworkCookie>&)");
    idx = m_backend->metaObject()->indexOfMethod(normalizedSignature);
    if (idx != -1) {
        int requestId = -1;
        QMetaMethod method = m_backend->metaObject()->method(idx);
        method.invoke(m_backend,
              Qt::DirectConnection,
              Q_RETURN_ARG(int, requestId),
              Q_ARG(QList<QNetworkCookie>, cookies));
    }
}

void ChromeCookieStore::setDbPath(const QString &path)
{
    // If path is a URL, strip the initial "file://"
    QString normalizedPath = path.startsWith("file://") ? path.mid(7) : path;

    if (normalizedPath != m_dbPath) {
        if (Q_UNLIKELY(!normalizedPath.startsWith('/'))) {
            qWarning() << "Invalid database path (must be absolute):" << path;
            return;
        }
        m_dbPath = normalizedPath;
        Q_EMIT dbPathChanged();
    }
}

QString ChromeCookieStore::dbPath () const
{
    return m_dbPath;
}
