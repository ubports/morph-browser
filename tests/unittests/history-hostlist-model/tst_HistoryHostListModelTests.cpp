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
#include "history-host-model.h"
#include "history-hostlist-model.h"
#include "history-timeframe-model.h"

class HistoryHostListModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryHostListModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        model = new HistoryHostListModel;
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

    void shouldUpdateHostListWhenInsertingEntries()
    {
        QSignalSpy spyRowsInserted(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QVERIFY(spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        QList<QVariant> args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), HistoryHostListModel::Host).toString(), QString("example.org"));

        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QVERIFY(spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(0, 0), HistoryHostListModel::Host).toString(), QString("example.com"));

        history->add(QUrl("http://example.org/test.html"), "Test page", QUrl());
        QVERIFY(spyRowsInserted.isEmpty());
        QCOMPARE(spyDataChanged.count(), 1);
        args = spyDataChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 1);
        QCOMPARE(args.at(1).toModelIndex().row(), 1);
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldUpdateHostListWhenRemovingEntries()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(100);
        QDateTime t0 = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QTest::qWait(100);
        QDateTime t1 = QDateTime::currentDateTimeUtc();
        QTest::qWait(100);
        history->add(QUrl("http://example.org/test"), "Example Domain", QUrl());
        QCOMPARE(model->rowCount(), 2);

        QSignalSpy spyRowsRemoved(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        timeframe->setEnd(t1);
        QVERIFY(spyRowsRemoved.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        QList<QVariant> args;
        bool changed = false;
        int expectedIndex = 1;
        while(!changed && !spyDataChanged.isEmpty()) {
            args = spyDataChanged.takeFirst();
            int start = args.at(0).toModelIndex().row();
            int end = args.at(1).toModelIndex().row();
            changed = (start <= expectedIndex) && (expectedIndex <= end);
        }
        QVERIFY(changed);
        QCOMPARE(model->rowCount(), 2);

        timeframe->setStart(t0);
        QCOMPARE(spyRowsRemoved.count(), 1);
        args = spyRowsRemoved.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), (HistoryTimeframeModel*) 0);
        QCOMPARE(model->rowCount(), 0);

        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel(history);
        timeframe2->setSourceModel(history);
        model->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), timeframe2);
        QCOMPARE(model->rowCount(), 3);
    }

    void shouldKeepHostsSorted()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://www.gogle.com/lawnmower"), "Gogle Lawn Mower", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        history->add(QUrl("file:///tmp/test.html"), "test", QUrl());
        history->add(QUrl("http://www.gogle.com/mail"), "Gogle Mail", QUrl());
        history->add(QUrl("https://mail.gogle.com/"), "Gogle Mail", QUrl());
        history->add(QUrl("https://es.wikipedia.org/wiki/Wikipedia:Portada"), "Wikipedia, la enciclopedia libre", QUrl());
        QCOMPARE(model->rowCount(), 7);
        QStringList hosts;
        hosts << "" << "es.wikipedia.org" << "example.com" << "example.org"
              << "mail.gogle.com" << "ubuntu.com" << "www.gogle.com";
        for (int i = 0; i < hosts.count(); ++i) {
            QModelIndex index = model->index(i, 0);
            QString host = model->data(index, HistoryHostListModel::Host).toString();
            HistoryHostModel* entries = model->data(index, HistoryHostListModel::Entries).value<HistoryHostModel*>();
            QVERIFY(!host.isNull());
            QVERIFY(!entries->host().isNull());
            QCOMPARE(host, hosts.at(i));
            QCOMPARE(entries->host(), host);
        }
    }

    void shouldExposeHostModels()
    {
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(100);
        history->add(QUrl("http://example.org/test.html"), "Test Page", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->rowCount(), 3);

        QModelIndex index = model->index(0, 0);
        QString host = model->data(index, HistoryHostListModel::Host).toString();
        QCOMPARE(host, QString("example.com"));
        HistoryHostModel* entries = model->data(index, HistoryHostListModel::Entries).value<HistoryHostModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.com/"));

        index = model->index(1, 0);
        host = model->data(index, HistoryHostListModel::Host).toString();
        QCOMPARE(host, QString("example.org"));
        entries = model->data(index, HistoryHostListModel::Entries).value<HistoryHostModel*>();
        QCOMPARE(entries->rowCount(), 2);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.org/test.html"));
        QCOMPARE(entries->data(entries->index(1, 0), HistoryModel::Url).toUrl(), QUrl("http://example.org/"));

        index = model->index(2, 0);
        host = model->data(index, HistoryHostListModel::Host).toString();
        QCOMPARE(host, QString("ubuntu.com"));
        entries = model->data(index, HistoryHostListModel::Entries).value<HistoryHostModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
    }
};

QTEST_MAIN(HistoryHostListModelTests)
#include "tst_HistoryHostListModelTests.moc"
