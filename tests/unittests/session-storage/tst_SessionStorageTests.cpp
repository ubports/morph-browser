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
#include <QtCore/QTemporaryFile>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "session-storage.h"

class SessionStorageTests : public QObject
{
    Q_OBJECT

private:
    SessionStorage* session;

private Q_SLOTS:
    void init()
    {
        session = new SessionStorage;
    }

    void cleanup()
    {
        delete session;
    }

    void shouldNotDoAnythingWithEmptyDataFile()
    {
        QVERIFY(session->dataFile().isEmpty());
        QVERIFY(!session->isLocked());
        session->store(QString("foobar")); // should be a no-op
        QVERIFY(session->retrieve().isEmpty());
    }

    void shouldSetDataFile()
    {
        QSignalSpy dataFileSpy(session, SIGNAL(dataFileChanged()));
        QSignalSpy lockedSpy(session, SIGNAL(lockedChanged()));

        // Set an invalid session file
        QString invalidDataFile("/f00/bAr/session.json");
        session->setDataFile(invalidDataFile);
        QCOMPARE(session->dataFile(), invalidDataFile);
        QCOMPARE(dataFileSpy.count(), 1);
        QCOMPARE(lockedSpy.count(), 0);
        QVERIFY(!session->isLocked());
        dataFileSpy.clear();

        // Set a valid session file
        QTemporaryFile file;
        QVERIFY(file.open());
        file.close();
        session->setDataFile(file.fileName());
        QCOMPARE(session->dataFile(), file.fileName());
        QCOMPARE(dataFileSpy.count(), 1);
        QCOMPARE(lockedSpy.count(), 1);
        QVERIFY(session->isLocked());
        dataFileSpy.clear();
        lockedSpy.clear();

        // Reset the session file
        session->setDataFile("");
        QCOMPARE(session->dataFile(), QString(""));
        QCOMPARE(dataFileSpy.count(), 1);
        QCOMPARE(lockedSpy.count(), 1);
        QVERIFY(!session->isLocked());
        dataFileSpy.clear();
        lockedSpy.clear();
    }

    void shouldStoreAndRetrieveCorrectlyAfterwards()
    {
        QTemporaryFile file;
        QVERIFY(file.open());
        file.close();
        session->setDataFile(file.fileName());
        QVERIFY(session->isLocked());
        QString data("f00bAr");
        session->store(data);
        QCOMPARE(session->retrieve(), data);

        delete session;
        session = new SessionStorage;
        session->setDataFile(file.fileName());
        QVERIFY(session->isLocked());
        QCOMPARE(session->retrieve(), data);
    }

    void shouldLockOutSecondInstance()
    {
        QTemporaryFile file;
        QVERIFY(file.open());
        file.close();
        session->setDataFile(file.fileName());
        QVERIFY(session->isLocked());

        SessionStorage session2;
        session2.setDataFile(session->dataFile());
        QVERIFY(!session2.isLocked());

        // Verify that the session that held the lock going away
        // doesn’t automagically make the next one acquire it
        // (this would be undesirable as it would allow the second
        // instance to overwrite the first session’s data).
        delete session;
        session = NULL;
        QVERIFY(!session2.isLocked());
    }
};

QTEST_MAIN(SessionStorageTests)
#include "tst_SessionStorageTests.moc"
