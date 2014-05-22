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

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDebug>


WebkitCookieStore::WebkitCookieStore(QObject *parent)
    : CookieStore(parent)
{}

Cookies WebkitCookieStore::doGetCookies()
{
    Cookies cookies;
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName (getFullDbPathName ());

    if (!db.open()) {
        qCritical() << "Could not open cookie database: " << getFullDbPathName() << db.lastError();
        return cookies;
    }

    QSqlQuery q(db);
    q.exec("SELECT cookieId, cookie FROM cookies;");

    while (q.next()) {
        cookies.insert(q.value(0).toString(), q.value(1).toString());
    }

    db.close();
    return cookies;
}

QDateTime WebkitCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(getFullDbPathName ());
    return dbFileInfo.lastModified();
}

void WebkitCookieStore::doSetCookies(Cookies cookies)
{
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName (getFullDbPathName ());

    if (!db.open())
    {
        qCritical() << "Could not open cookie database: " << getFullDbPathName() << db.lastError();
        Q_EMIT moved(false);
        return;
    }

    QSqlQuery q(db);
    q.exec("CREATE TABLE IF NOT EXISTS cookies "
           "(cookieId VARCHAR PRIMARY KEY, cookie BLOB)");
    q.exec ("DELETE FROM cookies;");

    q.prepare("INSERT INTO cookies (cookieId, cookie) "
              "VALUES (:cookieId, :cookie)");

    for (Cookies::const_iterator it = cookies.constBegin();
         it != cookies.constEnd();
         ++it)
    {
        q.bindValue(":cookieId", it.key());
        q.bindValue(":cookie", it.value());

        if (!q.exec()) {
            qWarning() << "Couldn't insert cookie into DB"
                       << it.key();
       }
    }

    db.close();

    Q_EMIT moved(true);
}

QString WebkitCookieStore::getFullDbPathName() const
{
    return QStandardPaths::standardLocations(QStandardPaths::HomeLocation)[0] + "/" + dbPath();
}

void WebkitCookieStore::setDbPath(const QString &path)
{
    if (path != m_dbPath)
    {
        m_dbPath = path;
        Q_EMIT dbPathChanged();
    }
}

QString WebkitCookieStore::dbPath () const
{
    return m_dbPath;
}

