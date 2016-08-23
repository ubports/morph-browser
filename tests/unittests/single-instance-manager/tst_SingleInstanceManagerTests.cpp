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
#include <QtCore/QStandardPaths>
#include <QtCore/QStringList>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "single-instance-manager.h"

class SingleInstanceManagerTests : public QObject
{
    Q_OBJECT

private:
    SingleInstanceManager* singleton;
    QSignalSpy* newInstanceSpy;

private Q_SLOTS:
    void init()
    {
        QStandardPaths::setTestModeEnabled(true);
        singleton = new SingleInstanceManager(this);
        newInstanceSpy = new QSignalSpy(singleton, SIGNAL(newInstanceLaunched(const QStringList&)));
    }

    void cleanup()
    {
        delete newInstanceSpy;
        delete singleton;
        QStandardPaths::setTestModeEnabled(false);
    }

    void test_cannot_run_twice_same_instance()
    {
        QVERIFY(singleton->run(QStringList(), "appid"));
        QVERIFY(!singleton->run(QStringList(), "appid"));
        QVERIFY(newInstanceSpy->isEmpty());
    }

    void test_arguments_passed_to_already_running_instance()
    {
        QVERIFY(singleton->run(QStringList(), "appid"));
        SingleInstanceManager other;
        QStringList args;
        args << QStringLiteral("foo") << QStringLiteral("bar") << QStringLiteral("baz");
        QVERIFY(!other.run(args, "appid"));
        newInstanceSpy->wait();
        QCOMPARE(newInstanceSpy->first().at(0).toStringList(), args);
    }

    void test_long_appid_arguments_passed_to_already_running_instance()
    {
        QString longAppId =
            "very-very-avery-avery-avery-avery-avery"
            "-avery-avery-avery-avery-avery-avery"
            "-_avery-avery-avery-avery-avery--long-aappid_1";
        QVERIFY(singleton->run(QStringList(), longAppId));
        SingleInstanceManager other;
        QStringList args;
        args << QStringLiteral("foo") << QStringLiteral("bar") << QStringLiteral("baz");
        QVERIFY(!other.run(args, longAppId));
        newInstanceSpy->wait();
        qDebug() << newInstanceSpy->first();
        QCOMPARE(newInstanceSpy->first().at(0).toStringList(), args);
    }
};

QTEST_MAIN(SingleInstanceManagerTests)

#include "tst_SingleInstanceManagerTests.moc"
