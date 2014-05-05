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
#include <QNetworkCookie>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>


ChromeCookieStore::ChromeCookieStore(QObject *parent):
    CookieStore(parent)
{
}

Cookies ChromeCookieStore::doGetCookies()
{
    Cookies cookies;
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(getFullDbPathName());

    if (!db.open()) {
        qCritical() << "Could not open cookie database: " << getFullDbPathName() << db.lastError();
        return cookies;
    }

    QSqlQuery q(db);
    q.exec("SELECT host_key, name, value, path, expires_utc, secure, httponly, has_expires FROM cookies;");

    while (q.next()) {
        /* The key is in fact ignored, but must be unique */
        QString key = q.value(0).toString() + q.value(1).toString();

        /* Build the cookie string from its parts */
        QNetworkCookie cookie(q.value(1).toString().toUtf8(),
                              q.value(2).toString().toUtf8());
        cookie.setSecure(q.value(5).toBool());
        cookie.setHttpOnly(q.value(6).toBool());
        if (q.value(7).toBool()) {
            /* Chrome uses Mon Jan 01 00:00:00 UTC 1601 as the epoch, hence the
             * magic number below */
            QDateTime expires = QDateTime::fromMSecsSinceEpoch(q.value(4).toULongLong() / 1000 - 11644473600000);
            cookie.setExpirationDate(expires);
        }
        cookie.setDomain(q.value(0).toString());
        cookie.setPath(q.value(3).toString());
        cookies.insert(key, QString::fromUtf8(cookie.toRawForm()));
    }

    db.close();
    return cookies;
}

QDateTime ChromeCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(getFullDbPathName());
    return dbFileInfo.lastModified();
}

void ChromeCookieStore::doSetCookies(Cookies cookies)
{
    // TODO This is not needed ATM
    qWarning() << Q_FUNC_INFO << "not implemented";
}

QString ChromeCookieStore::getFullDbPathName() const
{
    return dbPath().startsWith('/') ? dbPath() :
        QStandardPaths::standardLocations(QStandardPaths::HomeLocation)[0] + "/" + dbPath();
}

void ChromeCookieStore::setDbPath(const QString &path)
{
    // If path is a URL, strip the initial "file://"
    QString normalizedPath = path.startsWith("file://") ? path.mid(7) : path;

    if (normalizedPath != m_dbPath)
    {
        m_dbPath = normalizedPath;
        Q_EMIT dbPathChanged();
    }
}

QString ChromeCookieStore::dbPath () const
{
    return m_dbPath;
}
