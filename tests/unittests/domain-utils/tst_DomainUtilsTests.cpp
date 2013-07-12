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

// Qt
#include <QtTest/QtTest>

// local
#include "domain-utils.h"

class DomainUtilsTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void shouldExtractTopLevelDomainName_data()
    {
        QTest::addColumn<QUrl>("url");
        QTest::addColumn<QString>("domain");
        QTest::newRow("only SLD") << QUrl("http://ubuntu.com") << QString("ubuntu.com");
        QTest::newRow("SLD with www") << QUrl("http://www.ubuntu.com") << QString("ubuntu.com");
        QTest::newRow("SLD is www") << QUrl("http://www.com") << QString("www.com");
        QTest::newRow("subdomain") << QUrl("https://mail.google.com/foo/bar") << QString("google.com");
        QTest::newRow("subdomain with m") << QUrl("http://m.cnet.com") << QString("cnet.com");
        QTest::newRow("subdomain with mobile") << QUrl("http://mobile.nytimes.com") << QString("nytimes.com");
        QTest::newRow("ftp with subdomain") << QUrl("ftp://user:pwd@ftp.london.ac.uk/home/foobar") << QString("london.ac.uk");
        QTest::newRow("two-letter SLD") << QUrl("https://fb.com/foobar") << QString("fb.com");
        QTest::newRow("two-letter SLD with www") << QUrl("http://www.fb.com/foobar") << QString("fb.com");
        QTest::newRow("two-letter SLD with subdomain") << QUrl("http://m.espn.go.com") << QString("go.com");
        QTest::newRow("two-component TLD") << QUrl("http://bbc.co.uk") << QString("bbc.co.uk");
        QTest::newRow("another two-component TLD") << QUrl("http://disney.com.es") << QString("disney.com.es");
        QTest::newRow("two-component TLD with subdomain") << QUrl("http://www.foobar.bbc.co.uk") << QString("bbc.co.uk");
        QTest::newRow("local file") << QUrl("file:///home/foobar/test.txt") << DomainUtils::TOKEN_LOCAL;
        QTest::newRow("IPv4 address") << QUrl("http://192.168.1.1/config") << QString("192.168.1.1");
        QTest::newRow("IPv6 address") << QUrl("http://[2001:db8:85a3::8a2e:370:7334]/bleh") << QString("2001:db8:85a3::8a2e:370:7334");
        QTest::newRow("localhost") << QUrl("http://localhost:8080/foobar") << QString("localhost");
    }

    void shouldExtractTopLevelDomainName()
    {
        QFETCH(QUrl, url);
        QVERIFY(url.isValid());
        QFETCH(QString, domain);
        QCOMPARE(DomainUtils::extractTopLevelDomainName(url), domain);
    }
};

QTEST_MAIN(DomainUtilsTests)
#include "tst_DomainUtilsTests.moc"
