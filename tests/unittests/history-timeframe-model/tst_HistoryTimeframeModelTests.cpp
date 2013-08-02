/*
 * Copyright 2013 Canonical Ltd.
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
#include "history-model.h"
#include "history-timeframe-model.h"


class HistoryTimeframeModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;
    HistoryTimeframeModel* timeframe;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel;
        model->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(model);
    }

    void cleanup()
    {
        delete timeframe;
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(timeframe->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(timeframe, SIGNAL(sourceModelChanged()));
        timeframe->setSourceModel(model);
        QVERIFY(spy.isEmpty());
        HistoryModel* model2 = new HistoryModel;
        timeframe->setSourceModel(model2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(timeframe->sourceModel(), model2);
        timeframe->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(timeframe->sourceModel(), (HistoryModel*) 0);
        delete model2;
    }

    void shouldNotifyWhenChangingStart()
    {
        QSignalSpy spy(timeframe, SIGNAL(startChanged()));
        QDateTime start = QDateTime::currentDateTimeUtc();
        timeframe->setStart(start);
        QCOMPARE(timeframe->start(), start);
        QCOMPARE(spy.count(), 1);
        timeframe->setStart(start);
        QCOMPARE(spy.count(), 1);
        QTest::qWait(100);
        timeframe->setStart(QDateTime::currentDateTimeUtc());
        QCOMPARE(spy.count(), 2);
        timeframe->setStart(QDateTime());
        QCOMPARE(spy.count(), 3);
    }

    void shouldNotifyWhenChangingEnd()
    {
        QSignalSpy spy(timeframe, SIGNAL(endChanged()));
        QDateTime end = QDateTime::currentDateTimeUtc();
        timeframe->setEnd(end);
        QCOMPARE(timeframe->end(), end);
        QCOMPARE(spy.count(), 1);
        timeframe->setEnd(end);
        QCOMPARE(spy.count(), 1);
        QTest::qWait(100);
        timeframe->setEnd(QDateTime::currentDateTimeUtc());
        QCOMPARE(spy.count(), 2);
        timeframe->setEnd(QDateTime());
        QCOMPARE(spy.count(), 3);
    }

    void shouldMatchAllWhenNoBoundsSet()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(timeframe->rowCount(), 2);
    }

    void shouldFilterOutOlderEntries()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        QDateTime start = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(timeframe->rowCount(), 2);
        timeframe->setStart(start);
        QCOMPARE(timeframe->rowCount(), 1);
        QCOMPARE(timeframe->data(timeframe->index(0, 0), HistoryModel::Url).toUrl(),
                 QUrl("http://example.com"));
    }

    void shouldFilterOutMoreRecentEntries()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        QDateTime end = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(timeframe->rowCount(), 2);
        timeframe->setEnd(end);
        QCOMPARE(timeframe->rowCount(), 1);
        QCOMPARE(timeframe->data(timeframe->index(0, 0), HistoryModel::Url).toUrl(),
                 QUrl("http://example.org"));
    }

    void shouldFilterOutOlderAndMoreRecentEntries()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        QDateTime start = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        model->add(QUrl("http://ubuntu.com"), "Ubuntu", QUrl());
        QTest::qWait(100);
        QDateTime end = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(timeframe->rowCount(), 3);
        timeframe->setStart(start);
        timeframe->setEnd(end);
        QCOMPARE(timeframe->rowCount(), 1);
        QCOMPARE(timeframe->data(timeframe->index(0, 0), HistoryModel::Url).toUrl(),
                 QUrl("http://ubuntu.com"));
    }
};

QTEST_MAIN(HistoryTimeframeModelTests)
#include "tst_HistoryTimeframeModelTests.moc"
