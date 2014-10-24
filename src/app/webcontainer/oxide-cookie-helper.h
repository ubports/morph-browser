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

#ifndef OXIDE_COOKIE_HELPER_H
#define OXIDE_COOKIE_HELPER_H

#include <QList>
#include <QNetworkCookie>
#include <QObject>
#include <QString>

class OxideCookieHelperPrivate;
class OxideCookieHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QObject* oxideStoreBackend READ oxideStoreBackend \
               WRITE setOxideStoreBackend NOTIFY oxideStoreBackendChanged)

public:
    OxideCookieHelper(QObject* parent = 0);

    // oxideStoreBackend
    void setOxideStoreBackend(QObject* backend);
    QObject* oxideStoreBackend() const;

    static QList<QNetworkCookie> cookiesFromVariant(const QVariant& cookies);
    static QVariant variantFromCookies(const QList<QNetworkCookie>& cookies);

public Q_SLOTS:
    void setCookies(const QList<QNetworkCookie>& cookies);

Q_SIGNALS:
    void oxideStoreBackendChanged();
    void cookiesSet(const QList<QNetworkCookie>& failedCookies);

private:
    OxideCookieHelperPrivate* d_ptr;
    Q_DECLARE_PRIVATE(OxideCookieHelper)
};

#endif // OXIDE_COOKIE_HELPER_H
