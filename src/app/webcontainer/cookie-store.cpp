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

#include <QDebug>

#include "cookie-store.h"

CookieStore::CookieStore(QObject* parent):
    QObject(parent)
{
    qRegisterMetaType<Cookies>("Cookies");
}

Cookies CookieStore::cookies()
{
    return doGetCookies();
}

bool CookieStore::setCookies(Cookies cookies)
{
    if (doSetCookies(cookies)) {
        Q_EMIT cookiesChanged();
        return true;
    } else {
        return false;
    }
}

Cookies CookieStore::doGetCookies()
{
    return Cookies();
}

bool CookieStore::doSetCookies(Cookies cookies)
{
    Q_UNUSED(cookies);
}

QDateTime CookieStore::lastUpdateTimeStamp() const
{
    return _lastUpdateTimeStamp;
}

void CookieStore::updateLastUpdateTimestamp(const QDateTime& timestamp)
{
    _lastUpdateTimeStamp = timestamp;
}

void CookieStore::moveFrom(CookieStore* store)
{
    if (Q_UNLIKELY(!store))
        return;

    Cookies cookies = store->cookies();

    QDateTime lastRemoteCookieUpdate = store->lastUpdateTimeStamp();
    QDateTime lastLocalCookieUpdate = lastUpdateTimeStamp();

    if (lastRemoteCookieUpdate.isValid() &&
        lastLocalCookieUpdate.isValid() &&
        (lastRemoteCookieUpdate < lastLocalCookieUpdate))
    {
        Q_EMIT moved(false);
        return;
    }

    if (setCookies(cookies)) {
        Q_EMIT moved(true);
    } else {
        Q_EMIT moved(false);
    }
}
