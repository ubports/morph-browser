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
#include "domain-utils.h"
#include "history-model.h"
#include "history-domain-model.h"
#include "history-domainlist-model.h"
#include "history-domainlist-chronological-model.h"
#include "history-timeframe-model.h"

class HistoryDomainListChronologicalModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryDomainListModel* domainlist;
    HistoryDomainListChronologicalModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        domainlist = new HistoryDomainListModel;
        domainlist->setSourceModel(timeframe);
        model = new HistoryDomainListChronologicalModel;
        model->setSourceModel(domainlist);
    }

    void cleanup()
    {
        delete model;
        delete domainlist;
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
        model->setSourceModel(domainlist);
        QVERIFY(spy.isEmpty());
        HistoryDomainListModel* domainlist2 = new HistoryDomainListModel;
        model->setSourceModel(domainlist2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), domainlist2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (HistoryDomainListModel*) 0);
        delete domainlist2;
    }

    void shouldRemainSorted()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->data(model->index(0, 0), HistoryDomainListModel::Domain).toString(), QString("ubuntu.com"));
        QCOMPARE(model->data(model->index(1, 0), HistoryDomainListModel::Domain).toString(), QString("example.org"));
    }

    void shouldRemoveDomain() {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QSignalSpy spy(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        history->removeEntriesByDomain("ubuntu.com");
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
    }

    void shouldReturnDomain() {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QCOMPARE(model->get(0), QString("example.org"));
    }
};

QTEST_MAIN(HistoryDomainListChronologicalModelTests)
#include "tst_HistoryDomainListChronologicalModelTests.moc"
