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
#include "scheme-filter.h"
#include "intent-parser.h"

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

        QTest::newRow("Valid intent - host only")
                << "intent://scan/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "/"
                << "scan"
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - no host w/ uri")
                << "intent://scan/?a=1/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "?a=1"
                << "scan"
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - w/ host")
                << "intent://host/my/long/path?a=1/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "my/long/path?a=1"
                << "host"
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - w/o host & uri-path")
                << "intent://#Intent;scheme=trusper.referrertests;package=trusper.referrertests;end"
                << "trusper.referrertests"
                << "trusper.referrertests"
                << ""
                << ""
                << ""
                << ""
                << ""
                << true;

        QTest::newRow("Valid intent - w/o host & uri-path and extra /")
                << "intent:///#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << "/"
                << ""
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Valid intent - w/o host & uri-path impler syntax")
                << "intent://#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                << "zxing"
                << "com.google.zxing.client.android"
                << ""
                << ""
                << "com"
                << "com"
                << "BROWSABLE"
                << true;

        QTest::newRow("Invalid intent")
                << "intent:///#Inttent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
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
    }

    void applyFilters_data()
    {
        QTest::addColumn<QString>("intentUris");

        QTest::addColumn<QString>("filterFunctionSource");

        QTest::addColumn<QString>("scheme");
        QTest::addColumn<QString>("uri");
        QTest::addColumn<QString>("host");

        QTest::newRow("Valid intent - default filter function")
                << "intent://scan/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                <<  ""
                << "zxing"
                << "/"
                << "scan";

        QTest::newRow("Valid intent - default filter function")
                << "intent://scan/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                <<  "(function(result) {return {'scheme': result.scheme+'custom', 'path': result.path+'custom', 'host': result.host+'custom'}; })"
                << "zxingcustom"
                << "/custom"
                << "scancustom";

        QTest::newRow("Valid intent - no (optional) host in filter result")
                << "intent://host/my/long/path?a=1/#Intent;component=com;scheme=zxing;category=BROWSABLE;action=com;package=com.google.zxing.client.android;end"
                <<  "(function(result) {return {'scheme': result.scheme+'custom', 'path': result.path+'custom' }; })"
                << "zxingcustom"
                << "my/long/path?a=1custom"
                << "";
    }

    void applyFilters()
    {
        QFETCH(QString, intentUris);

        QFETCH(QString, filterFunctionSource);

        QFETCH(QString, scheme);
        QFETCH(QString, uri);
        QFETCH(QString, host);

        QMap<QString, QString> filters;
        filters["intent"] = filterFunctionSource;

        SchemeFilter sf(filters);

        QVariantMap r = sf.applyFilter(intentUris);
        QVERIFY(r.contains("scheme"));
        QVERIFY(r.contains("path"));

        QCOMPARE(r.value("scheme").toString(), scheme);
        QCOMPARE(r.value("host").toString(), host);
        QCOMPARE(r.value("path").toString(), uri);
    }
};

QTEST_MAIN(IntentFilterTests)
#include "tst_IntentFilterTests.moc"
