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
#include <QtCore/QByteArray>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QStandardPaths>
#include <QtTest/QtTest>

// local
#include "session-utils.h"

using namespace SessionUtils;

class SessionUtilsTests : public QObject
{
    Q_OBJECT

public:
    SessionUtilsTests();
    void clearXdgRuntimeDir();
    void startNewSession();

private Q_SLOTS:
    void initTestCase();
    void cleanup();
    void testNoSession();
    void testSingleSession();
    void testSessionRestart();

private:
    QByteArray m_xdgRuntimeDir;
};

SessionUtilsTests::SessionUtilsTests():
    QObject(),
    m_xdgRuntimeDir("/tmp/session-utils-test")
{
}

void SessionUtilsTests::clearXdgRuntimeDir()
{
    QDir xdgRuntimeDir(m_xdgRuntimeDir);
    xdgRuntimeDir.removeRecursively();
    xdgRuntimeDir.mkpath(".");
}

void SessionUtilsTests::startNewSession()
{
    /* Wait for some time, because the times on the files are only as
     * accurate as a second. */
    QTest::qWait(1100);

    QDir upstartSessionDir(QString(m_xdgRuntimeDir + "/upstart/sessions"));
    upstartSessionDir.mkpath(".");

    QString sessionFile = QString("%1.session").arg(qrand());
    QFile file(upstartSessionDir.filePath(sessionFile));
    file.open(QIODevice::WriteOnly);
    file.close();

    QTest::qWait(1100);
}

void SessionUtilsTests::initTestCase()
{
    qputenv("XDG_RUNTIME_DIR", m_xdgRuntimeDir);
    clearXdgRuntimeDir();
}

void SessionUtilsTests::cleanup()
{
    clearXdgRuntimeDir();
}

void SessionUtilsTests::testNoSession()
{
    QVERIFY(firstRun("myapp"));
    QVERIFY(firstRun("yourapp"));

    // If the Unity session never started, firstRun() should always return true
    QVERIFY(firstRun("myapp"));
    QVERIFY(firstRun("yourapp"));
}

void SessionUtilsTests::testSingleSession()
{
    startNewSession();

    QVERIFY(firstRun("myapp"));
    QVERIFY(firstRun("yourapp"));

    QVERIFY(!firstRun("myapp"));
    QVERIFY(!firstRun("yourapp"));
}

void SessionUtilsTests::testSessionRestart()
{
    startNewSession();

    QVERIFY(firstRun("myapp"));
    QVERIFY(!firstRun("myapp"));

    startNewSession();
    QVERIFY(firstRun("myapp"));
    QVERIFY(firstRun("yourapp"));

    QVERIFY(!firstRun("myapp"));
    QVERIFY(!firstRun("yourapp"));
}

QTEST_MAIN(SessionUtilsTests)
#include "tst_SessionUtilsTests.moc"
