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
#include "history-blacklisted-model.h"

class HistoryBlacklistedModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;
    HistoryTimeframeModel* timeframe;
    HistoryBlacklistedModel* blacklisted;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel;
        model->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(model);
        blacklisted = new HistoryBlacklistedModel;
        blacklisted->setSourceModel(timeframe);
        blacklisted->setDatabasePath(":memory:");
    }

    void cleanup()
    {
        delete blacklisted;
        delete timeframe;
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(blacklisted->rowCount(), 0);
    }

    void shouldReturnDatabasePath()
    {
        QCOMPARE(blacklisted->databasePath(), QString(":memory:"));
    }

    void shouldNotifyWhenSettingDatabasePath()
    {
        QSignalSpy spyPath(blacklisted, SIGNAL(databasePathChanged()));
        QSignalSpy spyReset(blacklisted, SIGNAL(modelReset()));

        blacklisted->setDatabasePath(":memory:");
        QVERIFY(spyPath.isEmpty());
        QVERIFY(spyReset.isEmpty());

        blacklisted->setDatabasePath("");
        QCOMPARE(spyPath.count(), 1);
        QCOMPARE(spyReset.count(), 1);
        QCOMPARE(blacklisted->databasePath(), QString(":memory:"));
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(blacklisted, SIGNAL(sourceModelChanged()));
        blacklisted->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel;
        blacklisted->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(blacklisted->sourceModel(), timeframe2);
        blacklisted->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(blacklisted->sourceModel(), (HistoryTimeframeModel*) 0);
        delete timeframe2;
    }

    void shouldMatchAllWhenNoBlacklistSet()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(blacklisted->rowCount(), 2);
    }

    void shouldFilterOutBlacklistedUrls()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(100);
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(blacklisted->rowCount(), 2);
        blacklisted->addToBlacklist(QUrl("http://example.org"));
        QCOMPARE(blacklisted->rowCount(), 1);
        QCOMPARE(blacklisted->data(blacklisted->index(0, 0), HistoryModel::Url).toUrl(),
                 QUrl("http://example.com"));
    }
};

QTEST_MAIN(HistoryBlacklistedModelTests)
#include "tst_HistoryBlacklistedModelTests.moc"
