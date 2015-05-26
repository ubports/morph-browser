/*
 * Copyright 2014-2015 Canonical Ltd.
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
#include "limit-proxy-model.h"
#include "top-sites-model.h"

class LimitProxyModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    TopSitesModel* topsites;
    LimitProxyModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        topsites = new TopSitesModel;
        topsites->setSourceModel(timeframe);
        model = new LimitProxyModel;
        model->setSourceModel(topsites);
    }

    void cleanup()
    {
        delete model;
        delete topsites;
        delete timeframe;
        delete history;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldLimitBeInitiallyMinusOne()
    {
        QCOMPARE(model->limit(), -1);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(topsites);
        QVERIFY(spy.isEmpty());
        TopSitesModel* topsites2 = new TopSitesModel;
        model->setSourceModel(topsites2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), topsites2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (TopSitesModel*) 0);
        delete topsites2;
    }

    void shouldLimitEntriesWithLimitSetBeforePopulating()
    {
        model->setLimit(2);

        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());

        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->unlimitedRowCount(), 3);
    }

    void shouldLimitEntriesWithLimitSetAfterPopulating()
    {
        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());

        model->setLimit(2);

        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->unlimitedRowCount(), 3);
    }

    void shouldNotLimitEntriesIfLimitIsMinusOne()
    {
        model->setLimit(-1);

        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());

        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), model->unlimitedRowCount());
    }

    void shouldNotLimitEntriesIfLimitIsGreaterThanRowCount()
    {
        model->setLimit(4);

        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());

        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), model->unlimitedRowCount());
    }

    void shouldUpdateRowCountAndNotifyAfterAnEntryIsRemoved()
    {
        model->setLimit(2);

        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QSignalSpy spyRemoved(model, SIGNAL(rowsRemoved(QModelIndex, int, int)));

        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());
        history->add(QUrl("http://example2.org/"), "Example 2 Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example3.org/"), "Example 3 Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example4.org/"), "Example 4 Domain", QUrl());

        history->removeEntryByUrl(QUrl("http://example1.org/"));

        QCOMPARE(spyChanged.count(), 1);
        QCOMPARE(spyRemoved.count(), 0);

        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example2.org/"));
        QCOMPARE(model->data(model->index(1, 0), HistoryModel::Url).toUrl(), QUrl("http://example3.org/"));

        QCOMPARE(model->unlimitedRowCount(), 3);
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldGetItemWithCorrectValues()
    {
        history->add(QUrl("http://example1.org/"), "Example 1 Domain", QUrl());

        QVariantMap item = model->get(0);
        QHash<int, QByteArray> roles = model->roleNames();

        QCOMPARE(roles.count(), item.count());

        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            QCOMPARE(model->data(model->index(0, 0), role), item.value(roleName));
        }
    }

    void shouldReturnEmptyItemIfGetOutOfBounds()
    {
        QVariantMap item = model->get(1);
        QCOMPARE(item.count(), 0);
    }

};

QTEST_MAIN(LimitProxyModelTests)
#include "tst_LimitProxyModelTests.moc"
