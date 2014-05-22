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
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

static int connectionCounter = 0;

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
    CookieStore(parent)
{
    QString connectionName =
        QString("chromeCookieStore-%1").arg(connectionCounter++);
    m_db = QSqlDatabase::addDatabase("QSQLITE", connectionName);
}

Cookies ChromeCookieStore::doGetCookies()
{
    Cookies cookies;
    m_db.setDatabaseName(getFullDbPathName());

    if (Q_UNLIKELY(!m_db.open())) {
        qCritical() << "Could not open cookie database:" << getFullDbPathName()
            << m_db.lastError();
        return cookies;
    }

    QSqlQuery q(m_db);
    q.exec("SELECT host_key, name, value, path, expires_utc, secure, httponly, has_expires FROM cookies;");

    while (q.next()) {
        /* Build the cookie string from its parts */
        QNetworkCookie cookie(q.value(1).toString().toUtf8(),
                              q.value(2).toString().toUtf8());
        cookie.setSecure(q.value(5).toBool());
        cookie.setHttpOnly(q.value(6).toBool());
        if (q.value(7).toBool()) {
            QDateTime expires = dateTimeFromChrome(q.value(4).toULongLong());
            cookie.setExpirationDate(expires);
        }
        cookie.setDomain(q.value(0).toString());
        cookie.setPath(q.value(3).toString());
        cookies.append(cookie.toRawForm());
    }

    m_db.close();
    return cookies;
}

QDateTime ChromeCookieStore::lastUpdateTimeStamp() const
{
    QFileInfo dbFileInfo(getFullDbPathName());
    return dbFileInfo.lastModified();
}

bool ChromeCookieStore::createDb()
{
    if (Q_UNLIKELY(!m_db.transaction())) return false;

    QSqlQuery q(m_db);
    bool ok;
    ok = q.exec("CREATE TABLE meta(key LONGVARCHAR NOT NULL UNIQUE PRIMARY KEY,"
                "value LONGVARCHAR)");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    ok = q.exec("CREATE TABLE cookies (creation_utc INTEGER NOT NULL UNIQUE PRIMARY KEY,"
                "host_key TEXT NOT NULL,"
                "name TEXT NOT NULL,"
                "value TEXT NOT NULL,"
                "path TEXT NOT NULL,"
                "expires_utc INTEGER NOT NULL,"
                "secure INTEGER NOT NULL,"
                "httponly INTEGER NOT NULL,"
                "last_access_utc INTEGER NOT NULL,"
                "has_expires INTEGER NOT NULL DEFAULT 1,"
                "persistent INTEGER NOT NULL DEFAULT 1,"
                "priority INTEGER NOT NULL DEFAULT 1,"
                "encrypted_value BLOB DEFAULT '')");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    ok = q.exec("CREATE INDEX domain ON cookies(host_key)");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    ok = q.exec("INSERT INTO meta (key, value) VALUES ('version', '7')");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    ok = q.exec("INSERT INTO meta (key, value) VALUES ('last_compatible_version', '5')");
    if (Q_UNLIKELY(!ok)) {
        m_db.rollback();
        return false;
    }

    return m_db.commit();
}

bool ChromeCookieStore::doSetCookies(Cookies cookies)
{
    m_db.setDatabaseName(getFullDbPathName());

    if (!m_db.open()) {
        qCritical() << "Could not open cookie database:" <<
            getFullDbPathName() << m_db.lastError().text();
        return false;
    }

    QSqlQuery q(m_db);
    // Check whether the table already exists
    q.exec("SELECT name FROM sqlite_master WHERE type='table' AND name='cookies'");
    if (!q.next() && !createDb()) {
        qCritical() << "Could not create cookie database:" <<
            getFullDbPathName() << m_db.lastError().text();
        return false;
    }

    QList<QNetworkCookie> parsedCookies;

    Q_FOREACH(const QByteArray &cookie, cookies) {
        parsedCookies.append(QNetworkCookie::parseCookies(cookie));
    }

    q.prepare("INSERT INTO cookies (creation_utc,"
              "host_key, name, value, path,"
              "expires_utc, secure, httponly, last_access_utc,"
              "has_expires, persistent, priority, encrypted_value) "
              "VALUES (:creation_utc,"
              ":host_key, :name, :value, :path,"
              ":expires_utc, :secure, :httponly, :last_access_utc,"
              ":has_expires, :persistent, :priority, :encrypted_value)");
    Q_FOREACH(const QNetworkCookie &cookie, parsedCookies) {
        q.bindValue(":creation_utc",
                    dateTimeToChrome(QDateTime::currentDateTimeUtc()));
        q.bindValue(":host_key", cookie.domain());
        q.bindValue(":name", cookie.name());
        q.bindValue(":value", cookie.value());
        q.bindValue(":path", cookie.path());
        q.bindValue(":expires_utc",
                    dateTimeToChrome(cookie.expirationDate().toUTC()));
        q.bindValue(":secure", cookie.isSecure());
        q.bindValue(":httponly", cookie.isHttpOnly());
        q.bindValue(":last_access_utc",
                    dateTimeToChrome(QDateTime::currentDateTimeUtc()));
        q.bindValue(":has_expires", cookie.expirationDate().isValid());
        q.bindValue(":persistent", true);
        q.bindValue(":priority", 1);
        q.bindValue(":encrypted_value", 1);
        q.exec();
    }

    m_db.close();

    return true;
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

    if (normalizedPath != m_dbPath) {
        m_dbPath = normalizedPath;
        Q_EMIT dbPathChanged();
    }
}

QString ChromeCookieStore::dbPath () const
{
    return m_dbPath;
}
