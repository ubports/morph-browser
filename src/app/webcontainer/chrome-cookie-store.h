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

#ifndef CHROME_COOKIE_STORE_H
#define CHROME_COOKIE_STORE_H

#include "cookie-store.h"

#include <QSqlDatabase>

class ChromeCookieStore : public CookieStore
{
    Q_OBJECT
    Q_PROPERTY(QString dbPath READ dbPath WRITE setDbPath NOTIFY dbPathChanged)
    Q_PROPERTY(QObject* oxideStoreBackend READ oxideStoreBackend WRITE setOxideStoreBackend NOTIFY oxideStoreBackendChanged)

public:
    ChromeCookieStore(QObject* parent = 0);

    // dbpaths
    void setDbPath(const QString& path);
    QString dbPath() const;

    // oxideStoreBackend
    void setOxideStoreBackend(QObject* backend);
    QObject* oxideStoreBackend() const;

    // CookieStore overrides
    QDateTime lastUpdateTimeStamp() const Q_DECL_OVERRIDE;

Q_SIGNALS:
    void dbPathChanged();
    void oxideStoreBackendChanged();

private Q_SLOTS:
    void cookiesReceived(const Cookies& cookies);
    void cookiesUpdated(bool status);

private:
    virtual void doGetCookies() Q_DECL_OVERRIDE;
    virtual void doSetCookies(const Cookies& cookies) Q_DECL_OVERRIDE;

private:
    QObject* m_backend;
    QString m_dbPath;
};

#endif // CHROME_COOKIE_STORE_H
