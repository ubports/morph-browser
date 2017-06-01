/*
 * Copyright 2013-2015 Canonical Ltd.
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

class HistoryDomainListModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryDomainListModel* model;

    void verifyDataChanged(QSignalSpy& spy, int row)
    {
        QList<QVariant> args;
        bool changed = false;
        while(!changed && !spy.isEmpty()) {
            args = spy.takeFirst();
            int start = args.at(0).toModelIndex().row();
            int end = args.at(1).toModelIndex().row();
            changed = (start <= row) && (row <= end);
        }
        QVERIFY(changed);
    }

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        model = new HistoryDomainListModel;
        model->setSourceModel(history);
    }

    void cleanup()
    {
        delete model;
        delete history;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldUpdateDomainListWhenInsertingEntries()
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
        QCOMPARE(model->data(model->index(0, 0), HistoryDomainListModel::Domain).toString(), QString("example.org"));

        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QVERIFY(spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(1, 0), HistoryDomainListModel::Domain).toString(), QString("example.com"));

        history->add(QUrl("http://example.org/test.html"), "Test page", QUrl());
        QVERIFY(spyRowsInserted.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        args = spyDataChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldUpdateDomainListWhenRemovingEntries()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.org/test"), "Example Domain", QUrl());
        QCOMPARE(model->rowCount(), 2);
        history->removeEntryByUrl(QUrl("http://example.org/test"));
        QCOMPARE(model->rowCount(), 2);
        history->removeEntryByUrl(QUrl("http://example.org/"));
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateDataWhenMovingEntries()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QTest::qWait(100);

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QVERIFY(spyRowsMoved.isEmpty());
    }

    void shouldUpdateDataWhenDataChanges()
    {
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        history->add(QUrl("http://example.org/foobar"), "Example Domain", QUrl());
        QVERIFY(spyRowsMoved.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        verifyDataChanged(spyDataChanged, 1);

        spyDataChanged.clear();
        history->add(QUrl("http://example.org/foobar"), "Example Domain 2", QUrl());
        QVERIFY(spyRowsMoved.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        verifyDataChanged(spyDataChanged, 1);
    }

    void shouldUpdateWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(history);
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(nullptr);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), (HistoryModel*) nullptr);
        QCOMPARE(model->rowCount(), 0);

        HistoryModel history2;
        model->setSourceModel(&history2);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), &history2);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldKeepDomainsSortedInsertionOrder()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        history->add(QUrl("http://www.gogle.com/lawnmower"), "Gogle Lawn Mower", QUrl());
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        history->add(QUrl("file:///tmp/test.html"), "test", QUrl());
        history->add(QUrl("http://www.gogle.com/mail"), "Gogle Mail", QUrl());
        history->add(QUrl("https://mail.gogle.com/"), "Gogle Mail", QUrl());
        history->add(QUrl("https://es.wikipedia.org/wiki/Wikipedia:Portada"), "Wikipedia, la enciclopedia libre", QUrl());
        QCOMPARE(model->rowCount(), 6);
        QStringList domains;
        domains << "example.org" << "gogle.com" << "example.com" << "ubuntu.com"
                << DomainUtils::TOKEN_LOCAL << "wikipedia.org";
        for (int i = 0; i < domains.count(); ++i) {
            QModelIndex index = model->index(i, 0);
            QString domain = model->data(index, HistoryDomainListModel::Domain).toString();
            HistoryDomainModel* entries = model->data(index, HistoryDomainListModel::Entries).value<HistoryDomainModel*>();
            QVERIFY(!domain.isNull());
            QVERIFY(!entries->domain().isNull());
            QCOMPARE(domain, domains.at(i));
            QCOMPARE(entries->domain(), domain);
        }
    }

    void shouldExposeDomainModels()
    {
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(100);
        history->add(QUrl("http://example.org/test.html"), "Test Page", QUrl());
        history->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->rowCount(), 3);

        QModelIndex index = model->index(0, 0);
        QString domain = model->data(index, HistoryDomainListModel::Domain).toString();
        QCOMPARE(domain, QString("example.com"));
        HistoryDomainModel* entries = model->data(index, HistoryDomainListModel::Entries).value<HistoryDomainModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.com/"));

        index = model->index(1, 0);
        domain = model->data(index, HistoryDomainListModel::Domain).toString();
        QCOMPARE(domain, QString("example.org"));
        entries = model->data(index, HistoryDomainListModel::Entries).value<HistoryDomainModel*>();
        QCOMPARE(entries->rowCount(), 2);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.org/test.html"));
        QCOMPARE(entries->data(entries->index(1, 0), HistoryModel::Url).toUrl(), QUrl("http://example.org/"));

        index = model->index(2, 0);
        domain = model->data(index, HistoryDomainListModel::Domain).toString();
        QCOMPARE(domain, QString("ubuntu.com"));
        entries = model->data(index, HistoryDomainListModel::Entries).value<HistoryDomainModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
    }

    void shouldReturnData()
    {
        QDateTime now = QDateTime::currentDateTimeUtc();
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QVERIFY(!model->data(QModelIndex(), HistoryDomainListModel::Domain).isValid());
        QVERIFY(!model->data(model->index(-1, 0), HistoryDomainListModel::Domain).isValid());
        QVERIFY(!model->data(model->index(3, 0), HistoryDomainListModel::Domain).isValid());
        QCOMPARE(model->data(model->index(0, 0), HistoryDomainListModel::Domain).toString(), QString("example.org"));
        QVERIFY(model->data(model->index(0, 0), HistoryDomainListModel::LastVisit).toDateTime() >= now);
        HistoryDomainModel* entries = model->data(model->index(0, 0), HistoryDomainListModel::Entries).value<HistoryDomainModel*>();
        QVERIFY(entries != 0);
        QCOMPARE(entries->rowCount(), 1);
        QVERIFY(!model->data(model->index(0, 0), HistoryDomainListModel::Entries + 3).isValid());
    }
};

QTEST_MAIN(HistoryDomainListModelTests)
#include "tst_HistoryDomainListModelTests.moc"
