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
#include "history-model.h"
#include "history-timeframe-model.h"
#include "history-hidden-model.h"

class HistoryHiddenModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;
    HistoryTimeframeModel* timeframe;
    HistoryHiddenModel* hidden;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel;
        model->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(model);
        hidden = new HistoryHiddenModel;
        hidden->setSourceModel(timeframe);
    }

    void cleanup()
    {
        delete hidden;
        delete timeframe;
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(hidden->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(hidden, SIGNAL(sourceModelChanged()));
        hidden->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel;
        hidden->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(hidden->sourceModel(), timeframe2);
        hidden->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(hidden->sourceModel(), (HistoryTimeframeModel*) 0);
        delete timeframe2;
    }

    void shouldMatchAllWhenNothingIsHide()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(hidden->rowCount(), 2);
    }

    void shouldFilterOutHiddenUrls()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(hidden->rowCount(), 2);
        model->hide(QUrl("http://example.org"));
        QCOMPARE(hidden->rowCount(), 1);
        QCOMPARE(hidden->data(hidden->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.com"));
    }
};

QTEST_MAIN(HistoryHiddenModelTests)
#include "tst_HistoryHiddenModelTests.moc"
