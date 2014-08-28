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

namespace {

QList<QNetworkCookie> networkCookiesFromVariantList(const QVariant& cookies) {
    if (!cookies.canConvert(QMetaType::QVariantList)) {
        return QList<QNetworkCookie>();
    }

    QList<QNetworkCookie> networkCookies;
    QList<QVariant> cl = cookies.toList();
    Q_FOREACH(QVariant cookie, cl) {
        if (!cookie.canConvert(QVariant::Map)) {
            continue;
        }

        QNetworkCookie nc;
        QVariantMap vm = cookie.toMap();
        if (!vm.contains("name") || !vm.contains("value")) {
            continue;
        }

        nc.setName(vm.value("name").toByteArray());
        nc.setValue(vm.value("value").toByteArray());
        nc.setDomain(vm.value("domain").toString());
        nc.setPath(vm.value("path").toString());
        if (vm.contains("httponly") &&
            vm.value("httponly").canConvert(QVariant::Bool)) {
            nc.setHttpOnly(vm.value("httponly").toBool());
        }

        if (vm.contains("issecure") &&
            vm.value("issecure").canConvert(QVariant::Bool)) {
            nc.setSecure(vm.value("issecure").toBool());
        }

        if (vm.contains("expirationdate") &&
            vm.value("expirationdate").canConvert(QVariant::LongLong)) {
            bool ok = false;
            qlonglong date = vm.value("expirationdate").toLongLong(&ok);
            if (ok)
            nc.setExpirationDate(QDateTime::fromMSecsSinceEpoch(date));
        }

        networkCookies.append(nc);
    }
    return networkCookies;
}

}

ChromeCookieStore::ChromeCookieStore(QObject* parent):
    CookieStore(parent), m_backend(0)
{}

void ChromeCookieStore::setHomepage(const QUrl& homepage) {
    if (homepage == m_homepage)
        return;

    m_homepage = homepage;

    emit homepageChanged();
}

QUrl ChromeCookieStore::homepage() const {
    return m_homepage;
}

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

void ChromeCookieStore::oxideCookiesReceived(int requestId, const QVariant& cookies, RequestStatus status)
{
    Q_UNUSED(requestId);
    Q_UNUSED(status);
    emit gotCookies(networkCookiesFromVariantList(cookies));
}

void ChromeCookieStore::oxideCookiesUpdated(int requestId, RequestStatus status)
{
    Q_UNUSED(requestId);
    emit cookiesSet(status == RequestStatusOK);
}

void ChromeCookieStore::doGetCookies()
{
    if ( ! m_backend)
        return;

    QObject::connect(m_backend,
                     SIGNAL(gotCookies(int, const QVariant&, RequestStatus)),
                     this,
                     SLOT(oxideCookiesReceived(int, const QVariant&, RequestStatus)));

    QMetaObject::invokeMethod(m_backend, "getAllCookies", Qt::DirectConnection);
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

    QObject::connect(m_backend, SIGNAL(cookiesSet(int, RequestStatus)),
                     this, SLOT(oxideCookiesUpdated(int, RequestStatus)));

    int requestId = -1;
    QString url = m_homepage.toString();
    QMetaObject::invokeMethod(m_backend, "setNetworkCookies",
                              Qt::DirectConnection,
                              Q_RETURN_ARG(int, requestId),
                              Q_ARG(const QString&, url),
                              Q_ARG(const QList<QNetworkCookie>&, cookies));
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
