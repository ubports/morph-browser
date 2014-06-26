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
#include "history-byvisits-model.h"
#include "limit-proxy-model.h"

class LimitProxyModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryByVisitsModel* byvisits;
    LimitProxyModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        byvisits = new HistoryByVisitsModel;
        byvisits->setSourceModel(timeframe);
        model = new LimitProxyModel;
        model->setSourceModel(byvisits);
    }

    void cleanup()
    {
        delete model;
        delete byvisits;
        delete timeframe;
        delete history;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(byvisits);
        QVERIFY(spy.isEmpty());
        HistoryByVisitsModel* byvisits2 = new HistoryByVisitsModel;
        model->setSourceModel(byvisits2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), byvisits2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (HistoryByVisitsModel*) 0);
        delete byvisits2;
    }

    void shouldLimitEntries()
    {
        model->setLimit(2);

        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());

        QCOMPARE(model->rowCount(), 2);
    }
};

QTEST_MAIN(LimitProxyModelTests)
#include "tst_LimitProxyModelTests.moc"
