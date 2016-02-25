/*
 * Copyright 2016 Canonical Ltd.
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
#include <QtCore/QObject>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "meminfo.h"

class MemInfoTests : public QObject
{
    Q_OBJECT

private:
    MemInfo* meminfo;

private Q_SLOTS:
    void init()
    {
        meminfo = new MemInfo(this);
    }

    void cleanup()
    {
        delete meminfo;
    }

    void test_active_property()
    {
        QVERIFY(meminfo->active());
        QSignalSpy spy(meminfo, SIGNAL(activeChanged()));

        meminfo->setActive(true);
        QVERIFY(spy.isEmpty());

        meminfo->setActive(false);
        QCOMPARE(spy.count(), 1);
        QVERIFY(!meminfo->active());
        spy.clear();

        meminfo->setActive(false);
        QVERIFY(spy.isEmpty());

        meminfo->setActive(true);
        QCOMPARE(spy.count(), 1);
        QVERIFY(meminfo->active());
    }

    void test_interval_property()
    {
        QCOMPARE(meminfo->interval(), 5000);
        QSignalSpy spy(meminfo, SIGNAL(intervalChanged()));

        meminfo->setInterval(5000);
        QVERIFY(spy.isEmpty());

        meminfo->setInterval(1500);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(meminfo->interval(), 1500);
    }

    void test_initial_values()
    {
        QCOMPARE(meminfo->total(), 0);
        QCOMPARE(meminfo->free(), 0);
    }

    void test_update()
    {
        QSignalSpy totalSpy(meminfo, SIGNAL(totalChanged()));
        QSignalSpy freeSpy(meminfo, SIGNAL(freeChanged()));
        meminfo->setInterval(100);
        totalSpy.wait();
        freeSpy.wait();
        QVERIFY(meminfo->total() > 0);
        QVERIFY(meminfo->free() > 0);
        QVERIFY(meminfo->total() > meminfo->free());
    }
};

QTEST_MAIN(MemInfoTests)

#include "tst_MemInfoTests.moc"
