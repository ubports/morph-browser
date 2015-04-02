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
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "domain-utils.h"
#include "history-model.h"
#include "history-timeframe-model.h"
#include "history-blacklisted-model.h"
#include "history-byvisits-model.h"

class HistoryByVisitsModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryBlacklistedModel* blacklisted;
    HistoryByVisitsModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        blacklisted = new HistoryBlacklistedModel;
        blacklisted->setSourceModel(timeframe);
        blacklisted->setDatabasePath(":memory:");
        model = new HistoryByVisitsModel;
        model->setSourceModel(blacklisted);
    }

    void cleanup()
    {
        delete model;
        delete timeframe;
        delete blacklisted;
        delete history;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(blacklisted);
        QVERIFY(spy.isEmpty());
        HistoryBlacklistedModel* blacklisted2 = new HistoryBlacklistedModel;
        model->setSourceModel(blacklisted2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), blacklisted2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (HistoryBlacklistedModel*) 0);
        delete blacklisted2;
    }

    void shouldBeSortedByVisits()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Domain).toString(), QString("ubuntu.com"));
        QCOMPARE(model->data(model->index(1, 0), HistoryModel::Domain).toString(), QString("example.org"));
    }
};

QTEST_MAIN(HistoryByVisitsModelTests)
#include "tst_HistoryByVisitsModelTests.moc"
