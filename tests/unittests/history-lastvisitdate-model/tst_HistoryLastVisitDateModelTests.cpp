/*
 * Copyright 2015 Canonical Ltd.
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
#include "history-lastvisitdate-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"


class HistoryLastVisitDateModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryLastVisitDateModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        model = new HistoryLastVisitDateModel;
        model->setSourceModel(timeframe);
    }

    void cleanup()
    {
        delete model;
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
        model->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel(model);
        model->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), timeframe2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (HistoryTimeframeModel*) 0);
    }

    void shouldNotifyWhenChangingLastVisitDate()
    {
        QSignalSpy spy(model, SIGNAL(lastVisitDateChanged()));
        model->setLastVisitDate(QDate());
        QVERIFY(spy.isEmpty());
        model->setLastVisitDate(QDate::currentDate());
        QCOMPARE(spy.count(), 1);
    }

    void shouldMatchAllWhenNoLastVisitDateSet()
    {
        history->add(QUrl("http://example.org"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldFilterOutNonMatchingLastVisitDate()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        model->setLastVisitDate(QDate::currentDate());
        QCOMPARE(model->rowCount(), 2);
        model->setLastVisitDate(QDate(1970, 1, 1));
        QCOMPARE(model->rowCount(), 0);
    }
};

QTEST_MAIN(HistoryLastVisitDateModelTests)
#include "tst_HistoryLastVisitDateModelTests.moc"
