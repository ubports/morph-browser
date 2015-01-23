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
#include "src/app/webcontainer/intent-filter.h"

class IntentFilterTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void parseIntentUris_data()
    {
        QTest::addColumn<QString>("intentUris");

        QTest::addColumn<QString>("scheme");
        QTest::addColumn<QString>("package");
        QTest::addColumn<QString>("uri");
        QTest::addColumn<QString>("host");
        QTest::addColumn<QString>("action");
        QTest::addColumn<QString>("component");
        QTest::addColumn<QString>("category");

        QTest::addColumn<bool>("isValid");

        QTest::newRow("Valid intent - no host")
                << "intent://scan/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "scan"
                << ""
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - w/ host")
                << "intent://host/scan?a=1/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "scan?a=1"
                << "host"
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - w/ host")
                << "intent:///#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << ""
                << ""
                << ""
                << ""
                << ""
                << ""
                << ""
                << false;
    }

    void parseIntentUris()
    {
        QFETCH(QString, intentUris);

        QFETCH(QString, scheme);
        QFETCH(QString, package);
        QFETCH(QString, uri);
        QFETCH(QString, host);
        QFETCH(QString, action);
        QFETCH(QString, component);
        QFETCH(QString, category);

        QFETCH(bool, isValid);

        IntentUriDescription d = parseIntentUri(intentUris);

        QCOMPARE(d.scheme, scheme);
        QCOMPARE(d.package, package);
        QCOMPARE(d.uriPath, uri);
        QCOMPARE(d.host, host);
        QCOMPARE(d.action, action);
        QCOMPARE(d.component, component);
        QCOMPARE(d.category, category);

        QVERIFY(IntentFilter::isValidIntentDescription(d) == isValid);

        IntentFilter * pf = new IntentFilter
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

QTEST_MAIN(IntentFilterTests)
#include "tst_IntentFilterTests.moc"
