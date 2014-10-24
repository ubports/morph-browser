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

// Qt
#include <QtCore/QDir>
#include <QtCore/QList>
#include <QtCore/QSet>
#include <QtCore/QTimer>
#include <QtNetwork/QNetworkCookie>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "oxide-cookie-helper.h"

typedef QList<QNetworkCookie> Cookies;

/* Fake Oxide backend implementation */
class CookieBackend : public QObject
{
    Q_OBJECT

public:
    CookieBackend(QObject *parent = 0):
        QObject(parent),
        m_lastRequestId(0)
    {}

    void sendReply(int requestId, const QList<QNetworkCookie>& failedCookies) {
        QVariant failedCookiesVariant =
            OxideCookieHelper::variantFromCookies(failedCookies);
        Q_EMIT setCookiesResponse(requestId, failedCookiesVariant);
    }

    void setFailUrls(const QSet<QUrl>& urls) { m_failUrls = urls; }

public Q_SLOTS:
    int setNetworkCookies(const QUrl& url, const QList<QNetworkCookie>& cookies) {
        if (m_failUrls.contains(url)) return -1;
        m_lastRequestId++;
        /* Handle host cookies */
        QList<QNetworkCookie> restoredCookies;
        Q_FOREACH(const QNetworkCookie& cookie, cookies) {
            QNetworkCookie c(cookie);
            if (c.domain().isEmpty()) {
                c.setDomain(url.host());
            }
            restoredCookies.append(c);
        }
        Q_EMIT setNetworkCookiesCalled(m_lastRequestId, url, restoredCookies);
        return m_lastRequestId;
    }

    void onTimerTimeout() {
        QObject *timer = sender();
        int requestId = timer->property("requestId").toInt();
        Cookies failedCookies = timer->property("failedCookies").value<Cookies>();
        sendReply(requestId, failedCookies);
    }

Q_SIGNALS:
    void setCookiesResponse(int requestId, const QVariant& failedCookies);
    void setNetworkCookiesCalled(int requestId, const QUrl& url,
                                 const QList<QNetworkCookie>& cookies);
private:
    int m_lastRequestId;
    QSet<QUrl> m_failUrls;
};

class OxideCookieHelperTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testSetCookiesSanity();
    void testSetCookies_data();
    void testSetCookies();
    void testSetCookiesSubDomain();
    void testImmediateFailure_data();
    void testImmediateFailure();
};

void OxideCookieHelperTest::testSetCookiesSanity()
{
    OxideCookieHelper helper;
    QSignalSpy cookiesSet(&helper,
                          SIGNAL(cookiesSet(const QList<QNetworkCookie>&)));

    QVERIFY(helper.oxideStoreBackend() == 0);

    Cookies cookies = QNetworkCookie::parseCookies("a=2\nb=3");
    QCOMPARE(cookies.count(), 2);

    helper.setCookies(cookies);
    QTest::qWait(10);
    QCOMPARE(cookiesSet.count(), 0);

    CookieBackend backend;
    helper.setOxideStoreBackend(&backend);
    QCOMPARE(helper.oxideStoreBackend(), &backend);
    QCOMPARE(helper.property("oxideStoreBackend").value<QObject*>(),
             &backend);
}

void OxideCookieHelperTest::testSetCookies_data()
{
    QTest::addColumn<QString>("domain1");
    QTest::addColumn<QString>("cookies1");
    QTest::addColumn<int>("timeout1");
    QTest::addColumn<QString>("failedcookies1");

    QTest::addColumn<QString>("domain2");
    QTest::addColumn<QString>("cookies2");
    QTest::addColumn<int>("timeout2");
    QTest::addColumn<QString>("failedcookies2");

    QTest::addColumn<QString>("domain3");
    QTest::addColumn<QString>("cookies3");
    QTest::addColumn<int>("timeout3");
    QTest::addColumn<QString>("failedcookies3");

    QTest::newRow("empty") <<
        QString() << QString() << 0 << QString() <<
        QString() << QString() << 0 << QString() <<
        QString() << QString() << 0 << QString();

    QTest::newRow("one domain, success") <<
        "example.org" <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly\n"
        "c=something; Domain=example.org; Secure" << 10 << QString() <<
        QString() << QString() << 0 << QString() <<
        QString() << QString() << 0 << QString();

    QTest::newRow("one domain, with one failure") <<
        "example.org" <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly\n"
        "c=something; Domain=example.org; Secure" << 10 <<
        "b=2; Domain=example.org; HttpOnly" <<
        QString() << QString() << 0 << QString() <<
        QString() << QString() << 0 << QString();

    QTest::newRow("three domains, success") <<
        "example.org" <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "m=2; Domain=example.org; HttpOnly\n"
        "z=something; Domain=example.org; Secure" << 10 << QString() <<

        "domain.net" <<
        "c=4; Domain=domain.net; HttpOnly\n"
        "r=no; Domain=domain.net; Expires=Wed, 13 Jan 2021 22:23:01 GMT" << 20 << QString() <<

        "sub.site.org" <<
        "d=yes; Domain=sub.site.org; Secure\n"
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT" << 40 << QString();

    QTest::newRow("three domains, some failures") <<
        "example.org" <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "m=2; Domain=example.org; HttpOnly\n"
        "z=something; Domain=example.org; Secure" << 10 << QString() <<

        "domain.net" <<
        "c=4; Domain=domain.net; HttpOnly\n"
        "r=no; Domain=domain.net; Expires=Wed, 13 Jan 2021 22:23:01 GMT" << 40 <<
        "c=4; Domain=domain.net; HttpOnly" <<

        "sub.site.org" <<
        "d=yes; Domain=sub.site.org; Secure\n"
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT" << 20 <<
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT";
}

struct DomainData {
    DomainData(): timeout(0) {}
    DomainData(const QString& rawCookies, int t, const QString& rawFailedCookies):
        cookies(QNetworkCookie::parseCookies(rawCookies.toUtf8())),
        timeout(t),
        failedCookies(QNetworkCookie::parseCookies(rawFailedCookies.toUtf8()))
    {}

    Cookies cookies;
    int timeout;
    Cookies failedCookies;
};

static bool cookieCompare(const QNetworkCookie a, const QNetworkCookie b)
{
    return a.name() < b.name();
}

void OxideCookieHelperTest::testSetCookies()
{
    QFETCH(QString, domain1);
    QFETCH(QString, cookies1);
    QFETCH(int, timeout1);
    QFETCH(QString, failedcookies1);

    QFETCH(QString, domain2);
    QFETCH(QString, cookies2);
    QFETCH(int, timeout2);
    QFETCH(QString, failedcookies2);

    QFETCH(QString, domain3);
    QFETCH(QString, cookies3);
    QFETCH(int, timeout3);
    QFETCH(QString, failedcookies3);

    /* Build a data structure easier to handle */
    QMap<QString,DomainData> domains;
    if (!domain1.isEmpty()) domains[domain1] = DomainData(cookies1, timeout1, failedcookies1);
    if (!domain2.isEmpty()) domains[domain2] = DomainData(cookies2, timeout2, failedcookies2);
    if (!domain3.isEmpty()) domains[domain3] = DomainData(cookies3, timeout3, failedcookies3);

    OxideCookieHelper helper;
    QSignalSpy cookiesSet(&helper,
                          SIGNAL(cookiesSet(const QList<QNetworkCookie>&)));

    CookieBackend backend;
    QSignalSpy setNetworkCookiesCalled(&backend,
                                       SIGNAL(setNetworkCookiesCalled(int,const QUrl&,const QList<QNetworkCookie>&)));
    helper.setOxideStoreBackend(&backend);

    /* Build the list of cookies */
    Cookies cookies;
    Cookies expectedFailedCookies;
    Q_FOREACH(const DomainData &domainData, domains) {
        cookies.append(domainData.cookies);
        expectedFailedCookies.append(domainData.failedCookies);
    }
    qSort(cookies.begin(), cookies.end(), cookieCompare);

    helper.setCookies(cookies);
    QCOMPARE(setNetworkCookiesCalled.count(), domains.count());
    QList<QVariantList> setNetworkCookiesCalls = setNetworkCookiesCalled;
    Q_FOREACH(const QVariantList &args, setNetworkCookiesCalls) {
        int requestId = args.at(0).toInt();
        QUrl url = args.at(1).toUrl();
        Cookies domainCookies = args.at(2).value<Cookies>();

        QVERIFY(domains.contains(url.host()));
        /* Compare the cookies lists; we don't care about the order, so let's
         * sort them before comparing */
        const DomainData &domainData = domains[url.host()];
        qSort(domainCookies.begin(), domainCookies.end(), cookieCompare);
        Cookies expectedCookies = domainData.cookies;
        qSort(expectedCookies.begin(), expectedCookies.end(), cookieCompare);
        QCOMPARE(domainCookies, expectedCookies);

        QTimer* timer = new QTimer(&backend);
        timer->setSingleShot(true);
        timer->setInterval(domainData.timeout);
        timer->setProperty("requestId", requestId);
        timer->setProperty("failedCookies", QVariant::fromValue(domainData.failedCookies));
        QObject::connect(timer, SIGNAL(timeout()),
                         &backend, SLOT(onTimerTimeout()));
        timer->start();
    }

    QVERIFY(cookiesSet.wait());
    QCOMPARE(cookiesSet.count(), 1);

    /* Compare the failed cookies */
    qSort(expectedFailedCookies.begin(), expectedFailedCookies.end(), cookieCompare);
    Cookies failedCookies = cookiesSet.at(0).at(0).value<Cookies>();
    qSort(failedCookies.begin(), failedCookies.end(), cookieCompare);
    QCOMPARE(failedCookies, expectedFailedCookies);
}

void OxideCookieHelperTest::testSetCookiesSubDomain()
{
    OxideCookieHelper helper;
    QSignalSpy cookiesSet(&helper,
                          SIGNAL(cookiesSet(const QList<QNetworkCookie>&)));

    Cookies cookies = QNetworkCookie::parseCookies("a=2; Domain=.example.org");
    QCOMPARE(cookies.count(), 1);

    CookieBackend backend;
    QSignalSpy setNetworkCookiesCalled(&backend,
                                       SIGNAL(setNetworkCookiesCalled(int,const QUrl&,const QList<QNetworkCookie>&)));
    helper.setOxideStoreBackend(&backend);

    helper.setCookies(cookies);
    QCOMPARE(setNetworkCookiesCalled.count(), 1);
    QUrl url = setNetworkCookiesCalled.at(0).at(1).toUrl();

    QCOMPARE(url.host(), QString("example.org"));
}

void OxideCookieHelperTest::testImmediateFailure_data()
{
    QTest::addColumn<QString>("rawCookies");
    QTest::addColumn<QSet<QUrl> >("failUrls");
    QTest::addColumn<QString>("rawFailedcookies");

    QSet<QUrl> failUrls;

    failUrls.insert(QUrl("http://example.org"));
    QTest::newRow("one domain, one failure") <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly" <<
        failUrls <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly";
    failUrls.clear();

    failUrls.insert(QUrl("http://domain.net"));
    QTest::newRow("multiple domains, one failure") <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly\n"
        "c=4; Domain=domain.net; HttpOnly\n"
        "d=yes; Domain=sub.site.org; Secure\n"
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT" <<
        failUrls <<
        "c=4; Domain=domain.net; HttpOnly";
    failUrls.clear();

    failUrls.insert(QUrl("http://example.org"));
    failUrls.insert(QUrl("http://domain.net"));
    failUrls.insert(QUrl("http://sub.site.org"));
    QTest::newRow("multiple domains, all failures") <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly\n"
        "c=4; Domain=domain.net; HttpOnly\n"
        "d=yes; Domain=sub.site.org; Secure\n"
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT" <<
        failUrls <<
        "a=0; Domain=example.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT\n"
        "b=2; Domain=example.org; HttpOnly\n"
        "c=4; Domain=domain.net; HttpOnly\n"
        "d=yes; Domain=sub.site.org; Secure\n"
        "e=3; Domain=sub.site.org; HttpOnly\n"
        "z=last; Domain=sub.site.org; Expires=Wed, 13 Jan 2021 22:23:01 GMT";
    failUrls.clear();
}

void OxideCookieHelperTest::testImmediateFailure()
{
    QFETCH(QString, rawCookies);
    QFETCH(QSet<QUrl>, failUrls);
    QFETCH(QString, rawFailedcookies);

    OxideCookieHelper helper;
    QSignalSpy cookiesSet(&helper,
                          SIGNAL(cookiesSet(const QList<QNetworkCookie>&)));

    CookieBackend backend;
    QSignalSpy setNetworkCookiesCalled(&backend,
                                       SIGNAL(setNetworkCookiesCalled(int,const QUrl&,const QList<QNetworkCookie>&)));
    helper.setOxideStoreBackend(&backend);
    backend.setFailUrls(failUrls);

    /* Build the list of cookies */
    Cookies cookies = QNetworkCookie::parseCookies(rawCookies.toUtf8());
    Cookies expectedFailedCookies =
        QNetworkCookie::parseCookies(rawFailedcookies.toUtf8());

    helper.setCookies(cookies);

    /* If there were valid calls, reply to them */
    QList<QVariantList> setNetworkCookiesCalls = setNetworkCookiesCalled;
    Q_FOREACH(const QVariantList &args, setNetworkCookiesCalls) {
        int requestId = args.at(0).toInt();
        QUrl url = args.at(1).toUrl();
        Cookies domainCookies = args.at(2).value<Cookies>();

        QTimer* timer = new QTimer(&backend);
        timer->setSingleShot(true);
        timer->setInterval(5);
        timer->setProperty("requestId", requestId);
        QObject::connect(timer, SIGNAL(timeout()),
                         &backend, SLOT(onTimerTimeout()));
        timer->start();
    }

    QVERIFY(cookiesSet.wait());
    QCOMPARE(cookiesSet.count(), 1);

    /* Compare the failed cookies */
    qSort(expectedFailedCookies.begin(), expectedFailedCookies.end(), cookieCompare);
    Cookies failedCookies = cookiesSet.at(0).at(0).value<Cookies>();
    qSort(failedCookies.begin(), failedCookies.end(), cookieCompare);
    QCOMPARE(failedCookies, expectedFailedCookies);
}

QTEST_MAIN(OxideCookieHelperTest)
#include "tst_OxideCookieHelper.moc"
