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
#include "top-sites-model.h"

class TopSitesModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;
    HistoryTimeframeModel* timeframe;
    TopSitesModel* topsites;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel;
        model->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(model);
        topsites = new TopSitesModel;
        topsites->setSourceModel(timeframe);
    }

    void cleanup()
    {
        delete topsites;
        delete timeframe;
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(topsites->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(topsites, SIGNAL(sourceModelChanged()));
        topsites->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel;
        topsites->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(topsites->sourceModel(), timeframe2);
        topsites->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(topsites->sourceModel(), (HistoryTimeframeModel*) 0);
        delete timeframe2;
    }

    void shouldMatchAllWhenNothingIsHidden()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(topsites->rowCount(), 2);
    }

    void shouldFilterOutHiddenUrls()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(topsites->rowCount(), 2);
        model->hide(QUrl("http://example.org"));
        QCOMPARE(topsites->rowCount(), 1);
        QCOMPARE(topsites->data(topsites->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.com"));
    }

    void shouldBeSortedByVisits()
    {
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Domain).toString(), QString("ubuntu.com"));
        QCOMPARE(model->data(model->index(1, 0), HistoryModel::Domain).toString(), QString("example.org"));
    }
};

QTEST_MAIN(TopSitesModelTests)
#include "tst_TopSitesModelTests.moc"
