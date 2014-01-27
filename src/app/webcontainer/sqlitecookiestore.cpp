/*
 * Copyright 2013 Canonical Ltd.
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

#include "sqlitecookiestore.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDebug>


SqliteCookieStore::SqliteCookieStore(QObject *parent)
    : CookieStore(parent)
{}

Cookies SqliteCookieStore::doGetCookies()
{
    return Cookies();
}

QDateTime SqliteCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(getFullDbPathName ());
    return dbFileInfo.lastModified();
}

void SqliteCookieStore::doSetCookies(Cookies cookies)
{
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName (getFullDbPathName ());

    if ( ! db.open())
    {
        qCritical() << "Could not open cookie database: " << getFullDbPathName();
        Q_EMIT moved(false);
        return;
    }

    QSqlQuery q(db);
    q.exec ("DELETE FROM cookies;");

    q.prepare("INSERT INTO cookies (cookieId, cookie) "
              "VALUES (:cookieId, :cookie)");

    for (Cookies::const_iterator it = cookies.constBegin();
         it != cookies.constEnd();
         ++it)
    {
        q.bindValue(":cookieId", it.key());
        q.bindValue(":cookie", it.value());

        if ( ! q.exec())
        {
            qWarning() << "Couldn't insert cookie into DB"
                       << it.key();
       }
    }

    Q_EMIT moved(true);
}

QString SqliteCookieStore::getFullDbPathName() const
{
    return QStandardPaths::standardLocations(QStandardPaths::HomeLocation)[0] + "/" + dbPath();
}

void SqliteCookieStore::setDbPath(const QString &path)
{
    if (path != m_dbPath)
    {
        m_dbPath = path;
        Q_EMIT dbPathChanged();
    }
}

QString SqliteCookieStore::dbPath () const
{
    return m_dbPath;
}

