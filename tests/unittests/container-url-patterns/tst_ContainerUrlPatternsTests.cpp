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
#include <QtCore/QString>
#include <QtTest/QtTest>

// local
#include "url-pattern-utils.h"

class ContainerUrlPatternsTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void transformedUrlPatterns_data()
    {
        QTest::addColumn<QString>("pattern");
        QTest::addColumn<QString>("transformedPattern");
        QTest::addColumn<bool>("doTransformUrlPath");

        // regular patterns

        QTest::newRow("Valid pattern")
                << "https?://*.mydomain.com/*"
                << "https?://[^\\./]*.mydomain.com/[^\\s]*"
                << true;

        QTest::newRow("Valid pattern with no tail replacement")
                << "https?://*.mydomain.com/l.php\\?\\w+=([^&]+).*"
                << "https?://[^\\./]*.mydomain.com/l.php\\?\\w+=([^&]+).*"
                << false;

        QTest::newRow("Valid pattern - short url")
                << "https?://mydomain.com/*"
                << "https?://mydomain.com/[^\\s]*" << true;

        QTest::newRow("Valid pattern - strict url")
                << "https?://www.mydomain.com/*"
                << "https?://www.mydomain.com/[^\\s]*" << true;

#define WEBAPP_INVALID_URL_PATTERN_TEST(id,invalid_url_pattern) \
        QTest::newRow("Invalid pattern " #id) \
                << invalid_url_pattern \
                << QString() << true

        WEBAPP_INVALID_URL_PATTERN_TEST(1, "http");
        WEBAPP_INVALID_URL_PATTERN_TEST(2, "://");
        WEBAPP_INVALID_URL_PATTERN_TEST(3, "file://");
        WEBAPP_INVALID_URL_PATTERN_TEST(4, "https?://");
        WEBAPP_INVALID_URL_PATTERN_TEST(5, "https?://*");
        WEBAPP_INVALID_URL_PATTERN_TEST(6, "https?://foo.*");
        WEBAPP_INVALID_URL_PATTERN_TEST(7, "https?://foo.ba*r.com");
        WEBAPP_INVALID_URL_PATTERN_TEST(8, "https?://foo.*.com/");
        WEBAPP_INVALID_URL_PATTERN_TEST(9, "https?://foo.bar.*/");
        WEBAPP_INVALID_URL_PATTERN_TEST(10, "https?://*.bar.*");
        WEBAPP_INVALID_URL_PATTERN_TEST(11, "https?://*.bar.*/");
        WEBAPP_INVALID_URL_PATTERN_TEST(12, "https?://*.bar.*/");
        WEBAPP_INVALID_URL_PATTERN_TEST(13, "httpsfoo?://*.bar.com/");
        WEBAPP_INVALID_URL_PATTERN_TEST(14, "httppoo://*.bar.com/");

#undef WEBAPP_INVALID_URL_PATTERN_TEST

        // Google patterns

        QTest::newRow("Valid Google pattern")
                << "https?://mail.google.*/*"
                << "https?://mail.google.[^\\./]*/[^\\s]*" << true;

        QTest::newRow("Valid Google com SLD pattern")
                << "https?://mail.google.com.*/*"
                << "https?://mail.google.com.[^\\./]*/[^\\s]*" << true;

        QTest::newRow("Valid Google co SLD pattern")
                << "https?://mail.google.co.*/*"
                << "https?://mail.google.co.[^\\./]*/[^\\s]*" << true;

        QTest::newRow("Valid non Google pattern")
                << "https://*.google.com/*"
                << "https://[^\\./]*.google.com/[^\\s]*" << true;

#define WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(id,invalid_google_url_pattern) \
        QTest::newRow("Invalid Google App pattern " #id) \
                << invalid_google_url_pattern \
                << QString() << true

        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(1, "https://*.google.*/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(2, "https://service.gooo*gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(3, "https://service.gooo?gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(4, "https://service.goo*gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(5, "https://serv?ice.goo*gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(6, "https://se*rv?ice.goo*gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(7, "https://se*rvice.goo*gle.com/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(8, "https://se*rvice.goo*gle.*/*");
        WEBAPP_INVALID_GOOGLE_URL_PATTERN_TEST(8, "https://service.google.kom.*/*");
    }

    void transformedUrlPatterns()
    {
        QFETCH(QString, pattern);
        QFETCH(QString, transformedPattern);
        QFETCH(bool, doTransformUrlPath);
        QCOMPARE(UrlPatternUtils::transformWebappSearchPatternToSafePattern(pattern, doTransformUrlPath), transformedPattern);
    }

    void filteredUrlPatterns_data()
    {
        QTest::addColumn<QStringList>("patterns");
        QTest::addColumn<QStringList>("filteredPattern");

        // regular patterns

        QTest::newRow("Patterns with empty ones")
                << (QStringList() << QString("https?://*.mydomain.com/*")
                                  << QString()
                                  << QString("https?://www.mydomain.com/*")
                                  << QString())
                << (QStringList() << QString("https?://[^\\./]*.mydomain.com/[^\\s]*")
                                  << QString("https?://www.mydomain.com/[^\\s]*"));

        QTest::newRow("Patterns with invalid ones")
                << (QStringList() << QString("https?://*.mydomain.com/*")
                                  << QString()
                                  << QString("https?://*")
                                  << QString())
                << (QStringList() << QString("https?://[^\\./]*.mydomain.com/[^\\s]*"));
    }

    void filteredUrlPatterns()
    {
        QFETCH(QStringList, patterns);
        QFETCH(QStringList, filteredPattern);
        QCOMPARE(UrlPatternUtils::filterAndTransformUrlPatterns(patterns), filteredPattern);
    }
};

QTEST_MAIN(ContainerUrlPatternsTests)
#include "tst_ContainerUrlPatternsTests.moc"
