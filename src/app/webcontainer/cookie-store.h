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

#ifndef __COOKIE_STORE_H__
#define __COOKIE_STORE_H__

#include <QByteArray>
#include <QDateTime>
#include <QList>
#include <QNetworkCookie>
#include <QObject>
#include <QHash>

typedef QList<QNetworkCookie> Cookies;
Q_DECLARE_METATYPE(Cookies);

class CookieStoreRequest;

class CookieStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QDateTime lastUpdateTimeStamp READ lastUpdateTimeStamp \
               NOTIFY lastUpdateTimeStampChanged)

public:
    CookieStore(QObject* parent = 0);

    virtual QDateTime lastUpdateTimeStamp() const;

    Q_INVOKABLE void getCookies();
    Q_INVOKABLE void setCookies(const Cookies& cookies);
    Q_INVOKABLE void moveFrom(CookieStore* store);

Q_SIGNALS:
    void moved(bool);
    void lastUpdateTimeStampChanged();
    void gotCookies(const Cookies& cookies);
    void cookiesSet(bool status);

private Q_SLOTS:
    void cookiesReceived(const Cookies& cookies, CookieStoreRequest* request);

protected:
    void updateLastUpdateTimestamp(const QDateTime& timestamp);

private:
    virtual void doGetCookies();
    virtual void doSetCookies(const Cookies& Cookies);

private:

    QHash<CookieStoreRequest*, bool> _currentStoreRequests;
    QDateTime _lastUpdateTimeStamp;
};

#endif // __COOKIE_STORE_H__
