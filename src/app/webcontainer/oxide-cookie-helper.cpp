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

#include "oxide-cookie-helper.h"

#include <QDateTime>
#include <QDebug>
#include <QMap>
#include <QMetaMethod>
#include <QUrl>

typedef QList<QNetworkCookie> Cookies;

class OxideCookieHelperPrivate : public QObject
{
    Q_OBJECT
    Q_DECLARE_PUBLIC(OxideCookieHelper)

public:
    OxideCookieHelperPrivate(OxideCookieHelper* q);

    void setCookies(const QList<QNetworkCookie>& cookies);
    QList<QNetworkCookie> cookiesWithDomain(const QList<QNetworkCookie>& cookies,
                                            const QString& domain);

private Q_SLOTS:
    void oxideCookiesUpdated(int requestId, const QVariant& failedCookiesVariant);

private:
    QObject* m_backend;
    QMap<int, QString> m_pendingCalls;
    QList<QNetworkCookie> m_failedCookies;
    mutable OxideCookieHelper* q_ptr;
};

OxideCookieHelperPrivate::OxideCookieHelperPrivate(OxideCookieHelper* q):
    QObject(q),
    m_backend(0),
    q_ptr(q)
{
    qRegisterMetaType<QList<QNetworkCookie> >();
}

void OxideCookieHelperPrivate::setCookies(const QList<QNetworkCookie>& cookies)
{
    Q_Q(OxideCookieHelper);

    if (Q_UNLIKELY(!m_backend)) {
        qCritical() << "No Oxide backend set!";
        return;
    }

    if (Q_UNLIKELY(!m_pendingCalls.isEmpty())) {
        qCritical() << "A call to setCookies() is already in progress";
        return;
    }

    m_failedCookies.clear();

    if (cookies.isEmpty()) {
        /* We don't simply use Q_EMIT because we want the signal to be emitted
         * asynchronously */
        QMetaObject::invokeMethod(q, "cookiesSet", Qt::QueuedConnection,
                                  Q_ARG(QList<QNetworkCookie>, cookies));
        return;
    }

    /* Since Oxide does not support setting cookies for different domains in a
     * single call to setCookies(), we group the cookies by their domain, and
     * perform a separate call to Oxide's setCookies() for each domain.
     *
     * Cookies whose domain doesn't start with a "." are host cookies, and need
     * to be treated specially: we will use their domain as host (that is, we
     * will pass it as first argument in the setNetworkCookies() call), and
     * will unset their domain in the cookie.
     */
    QMap<QString, Cookies> cookiesPerHost;
    Q_FOREACH(const QNetworkCookie &cookie, cookies) {
        QNetworkCookie c(cookie);
        /* We use the domain (without any starting dot) as host */
        QString host = c.domain();
        if (host.startsWith('.')) {
            host = host.mid(1);
        } else {
            /* No starting dot => this is a host cookie */
            c.setDomain(QString());
        }
        /* This creates an empty list if the host is new in the map */
        QList<QNetworkCookie> &domainCookies =
            cookiesPerHost[host];

        domainCookies.append(c);
    }

    /* Grouping done, perform the calls */
    QMapIterator<QString, Cookies> it(cookiesPerHost);
    while (it.hasNext()) {
        it.next();

        QUrl url;
        url.setScheme("http");
        url.setHost(it.key());

        int requestId = -1;
        QMetaObject::invokeMethod(m_backend, "setNetworkCookies",
                                  Qt::DirectConnection,
                                  Q_RETURN_ARG(int, requestId),
                                  Q_ARG(QUrl, url),
                                  Q_ARG(QList<QNetworkCookie>, it.value()));
        if (Q_UNLIKELY(requestId == -1)) {
            m_failedCookies.append(cookiesWithDomain(it.value(), url.host()));
        } else {
            m_pendingCalls.insert(requestId, url.host());
        }
    }

    /* If all the calls failed, we need to emit a reply here */
    if (m_pendingCalls.isEmpty()) {
        /* We don't simply use Q_EMIT because we want the signal to be emitted
         * asynchronously */
        QMetaObject::invokeMethod(q, "cookiesSet", Qt::QueuedConnection,
                                  Q_ARG(QList<QNetworkCookie>, m_failedCookies));
    }
}

QList<QNetworkCookie>
OxideCookieHelperPrivate::cookiesWithDomain(const QList<QNetworkCookie>& cookies,
                                            const QString& domain)
{
    QList<QNetworkCookie> restoredCookies;
    Q_FOREACH(const QNetworkCookie& cookie, cookies) {
        QNetworkCookie c(cookie);
        if (c.domain().isEmpty()) {
            c.setDomain(domain);
        }
        restoredCookies.append(c);
    }
    return restoredCookies;
}

void OxideCookieHelperPrivate::oxideCookiesUpdated(int requestId,
                                                   const QVariant& failedCookiesVariant)
{
    Q_Q(OxideCookieHelper);

    QString host = m_pendingCalls.value(requestId);
    QList<QNetworkCookie> failedCookies =
        OxideCookieHelper::cookiesFromVariant(failedCookiesVariant);
    m_failedCookies.append(cookiesWithDomain(failedCookies, host));
    m_pendingCalls.remove(requestId);

    if (m_pendingCalls.isEmpty()) {
        Q_EMIT q->cookiesSet(m_failedCookies);
    }
}

OxideCookieHelper::OxideCookieHelper(QObject* parent):
    QObject(parent),
    d_ptr(new OxideCookieHelperPrivate(this))
{
}

QList<QNetworkCookie>
OxideCookieHelper::cookiesFromVariant(const QVariant& cookies)
{
    if (!cookies.canConvert(QMetaType::QVariantList)) {
        return QList<QNetworkCookie>();
    }

    QList<QNetworkCookie> networkCookies;
    QList<QVariant> cl = cookies.toList();
    Q_FOREACH(QVariant cookie, cl) {
        if (!cookie.canConvert(QVariant::Map)) {
            continue;
        }

        QNetworkCookie nc;
        QVariantMap vm = cookie.toMap();
        if (!vm.contains("name") || !vm.contains("value")) {
            continue;
        }

        nc.setName(vm.value("name").toByteArray());
        nc.setValue(vm.value("value").toByteArray());
        nc.setDomain(vm.value("domain").toString());
        nc.setPath(vm.value("path").toString());
        if (vm.contains("httponly") &&
            vm.value("httponly").canConvert(QVariant::Bool)) {
            nc.setHttpOnly(vm.value("httponly").toBool());
        }

        if (vm.contains("issecure") &&
            vm.value("issecure").canConvert(QVariant::Bool)) {
            nc.setSecure(vm.value("issecure").toBool());
        }

        if (vm.contains("expirationdate")) {
            QVariant value = vm.value("expirationdate");
            if (value.canConvert(QVariant::DateTime)) {
                nc.setExpirationDate(value.toDateTime());
            } else if (value.canConvert(QVariant::LongLong)) {
                bool ok = false;
                qlonglong date = value.toLongLong(&ok);
                if (ok)
                    nc.setExpirationDate(QDateTime::fromMSecsSinceEpoch(date));
            }
        }

        networkCookies.append(nc);
    }
    return networkCookies;
}

QVariant
OxideCookieHelper::variantFromCookies(const QList<QNetworkCookie>& cookies)
{
    /* Taken straight from Oxide's networkCookiesToVariant() method defined in
     * qt/quick/api/oxideqquickwebcontext.cc
     */
    QList<QVariant> list;
    Q_FOREACH(QNetworkCookie cookie, cookies) {
        QVariantMap c;
        c.insert("name", QVariant(QString(cookie.name())));
        c.insert("value", QVariant(QString(cookie.value())));
        c.insert("domain", QVariant(cookie.domain()));
        c.insert("path", QVariant(cookie.path()));
        c.insert("httponly", QVariant(cookie.isHttpOnly()));
        c.insert("issecure", QVariant(cookie.isSecure()));
        c.insert("issessioncookie", QVariant(cookie.isSessionCookie()));
        if (cookie.expirationDate().isValid()) {
            c.insert("expirationdate", QVariant(cookie.expirationDate()));
        } else {
            c.insert("expirationdate", QVariant());
        }

        list.append(c);
    }

    return QVariant(list);

}

void OxideCookieHelper::setOxideStoreBackend(QObject* backend)
{
    Q_D(OxideCookieHelper);

    if (d->m_backend == backend)
        return;

    if (d->m_backend) {
        QObject::disconnect(d->m_backend, 0, this, 0);
    }

    d->m_backend = backend;
    if (backend) {
        QObject::connect(backend, SIGNAL(setCookiesResponse(int, const QVariant&)),
                         d, SLOT(oxideCookiesUpdated(int, const QVariant&)));
    }

    Q_EMIT oxideStoreBackendChanged();
}

QObject* OxideCookieHelper::oxideStoreBackend() const
{
    Q_D(const OxideCookieHelper);
    return d->m_backend;
}

void OxideCookieHelper::setCookies(const QList<QNetworkCookie>& cookies)
{
    Q_D(OxideCookieHelper);
    d->setCookies(cookies);
}

#include "oxide-cookie-helper.moc"
