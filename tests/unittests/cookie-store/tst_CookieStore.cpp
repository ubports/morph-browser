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
#include <QtCore/QSet>
#include <QtCore/QTemporaryDir>
#include <QtNetwork/QNetworkCookie>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "chrome-cookie-store.h"
#include "online-accounts-cookie-store.h"

uint qHash(const QNetworkCookie &cookie, uint seed)
{
    return qHash(cookie.toRawForm(), seed);
}

class CookieStoreTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testChromeProperties();
};

void CookieStoreTest::testChromeProperties()
{
    QTemporaryDir tmpDir;
    QVERIFY(tmpDir.isValid());
    QDir testDir(tmpDir.path());
    QTemporaryDir tmpDir2;
    QVERIFY(tmpDir2.isValid());
    QDir testDir2(tmpDir2.path());

    ChromeCookieStore store;
    QSignalSpy dbPathChanged(&store, SIGNAL(dbPathChanged()));

    QString path = testDir.filePath("cookies.db");
    store.setProperty("dbPath", path);
    QCOMPARE(dbPathChanged.count(), 1);
    QCOMPARE(store.property("dbPath").toString(), path);
    dbPathChanged.clear();

    QString path2 = testDir2.filePath("cookies.db");
    store.setProperty("dbPath", "file://" + path2);
    QCOMPARE(dbPathChanged.count(), 1);
    QCOMPARE(store.property("dbPath").toString(), path2);

    QVERIFY(store.property("cookies").value<Cookies>().isEmpty());
}

QTEST_MAIN(CookieStoreTest)
#include "tst_CookieStore.moc"
