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

public:
    ChromeCookieStore(QObject* parent = 0);

    void setDbPath(const QString& path);
    QString dbPath() const;

    QDateTime lastUpdateTimeStamp() const Q_DECL_OVERRIDE;

Q_SIGNALS:
    void dbPathChanged();

private:
    virtual Cookies doGetCookies() Q_DECL_OVERRIDE;
    virtual bool doSetCookies(const Cookies& cookies) Q_DECL_OVERRIDE;

    QString getFullDbPathName() const;
    bool createDb();

private:
    QString m_dbPath;
    QSqlDatabase m_db;
};

#endif // CHROME_COOKIE_STORE_H
