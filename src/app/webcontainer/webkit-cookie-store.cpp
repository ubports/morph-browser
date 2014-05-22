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

#include "webkit-cookie-store.h"

#include <QDebug>
#include <QFileInfo>
#include <QNetworkCookie>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

static int connectionCounter = 0;

WebkitCookieStore::WebkitCookieStore(QObject* parent):
    CookieStore(parent)
{
    QString connectionName =
        QString("webkitCookieStore-%1").arg(connectionCounter++);
    m_db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
}

Cookies WebkitCookieStore::doGetCookies()
{
    Cookies cookies;
    m_db.setDatabaseName(getFullDbPathName());

    if (!m_db.open()) {
        qCritical() << "Could not open cookie database:" << getFullDbPathName() << m_db.lastError();
        return cookies;
    }

    QSqlQuery q(m_db);
    q.exec("SELECT cookie FROM cookies;");

    while (q.next()) {
        cookies.append(q.value(0).toString().toUtf8());
    }

    m_db.close();
    return cookies;
}

QDateTime WebkitCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(getFullDbPathName());
    return dbFileInfo.lastModified();
}

bool WebkitCookieStore::doSetCookies(Cookies cookies)
{
    m_db.setDatabaseName(getFullDbPathName());

    if (!m_db.open()) {
        qCritical() << "Could not open cookie database:" << getFullDbPathName() << m_db.lastError();
        return false;
    }

    QSqlQuery q(m_db);
    q.exec("CREATE TABLE IF NOT EXISTS cookies "
           "(cookieId VARCHAR PRIMARY KEY, cookie BLOB)");
    q.exec ("DELETE FROM cookies;");

    q.prepare("INSERT INTO cookies (cookieId, cookie) "
              "VALUES (:cookieId, :cookie)");

    Q_FOREACH(const QByteArray& cookie, cookies) {
        /* The unique key is the hostname + the cookie name */
        QList<QNetworkCookie> parsed = QNetworkCookie::parseCookies(cookie);
        if (parsed.isEmpty()) continue;

        const QNetworkCookie& c = parsed.first();
        q.bindValue(":cookieId", c.domain() + c.name());
        q.bindValue(":cookie", cookie);

        if (!q.exec()) {
            qWarning() << "Couldn't insert cookie into DB" << cookie;
        }
    }

    m_db.close();

    return true;
}

QString WebkitCookieStore::getFullDbPathName() const
{
    return dbPath().startsWith('/') ? dbPath() :
        QStandardPaths::standardLocations(QStandardPaths::HomeLocation)[0] + "/" + dbPath();
}

void WebkitCookieStore::setDbPath(const QString& path)
{
    if (path != m_dbPath) {
        m_dbPath = path;
        Q_EMIT dbPathChanged();
    }
}

QString WebkitCookieStore::dbPath() const
{
    return m_dbPath;
}

