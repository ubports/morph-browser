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
#include "oxide-cookie-helper.h"

#include <QDebug>
#include <QFileInfo>
#include <QStandardPaths>

ChromeCookieStore::ChromeCookieStore(QObject* parent):
    CookieStore(parent),
    m_cookieHelper(new OxideCookieHelper(this))
{
    QObject::connect(m_cookieHelper, SIGNAL(oxideStoreBackendChanged()),
                     this, SIGNAL(oxideStoreBackendChanged()));
    QObject::connect(m_cookieHelper, SIGNAL(cookiesSet(const QList<QNetworkCookie>&)),
                     this, SLOT(oxideCookiesUpdated(const QList<QNetworkCookie>&)));
}

void ChromeCookieStore::setOxideStoreBackend(QObject* backend)
{
    m_cookieHelper->setOxideStoreBackend(backend);
}

QObject* ChromeCookieStore::oxideStoreBackend() const
{
    return m_cookieHelper->oxideStoreBackend();
}

void ChromeCookieStore::oxideCookiesReceived(int requestId, const QVariant& cookies)
{
    Q_UNUSED(requestId);
    emit gotCookies(OxideCookieHelper::cookiesFromVariant(cookies));
}

void ChromeCookieStore::oxideCookiesUpdated(const QList<QNetworkCookie>& failedCookies)
{
    if (!failedCookies.isEmpty()) {
        qWarning() << "Couldn't set some cookies:" << failedCookies;
    }
    emit cookiesSet(failedCookies.isEmpty());
}

void ChromeCookieStore::doGetCookies()
{
    QObject* backend = m_cookieHelper->oxideStoreBackend();
    if ( ! backend)
        return;

    QObject::connect(backend,
                     SIGNAL(getCookiesResponse(int, const QVariant&)),
                     this,
                     SLOT(oxideCookiesReceived(int, const QVariant&)));

    QMetaObject::invokeMethod(backend, "getAllCookies", Qt::DirectConnection);
}

QDateTime ChromeCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(m_dbPath);
    return dbFileInfo.lastModified();
}

void ChromeCookieStore::doSetCookies(const Cookies& cookies)
{
    m_cookieHelper->setCookies(cookies);
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
