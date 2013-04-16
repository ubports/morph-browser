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
#include <QtCore/QDir>
#include <QtCore/QTemporaryFile>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "history-model.h"

class HistoryModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel(":memory:");
    }

    void cleanup()
    {
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotAddEmptyUrl()
    {
        QCOMPARE(model->add(QUrl(), "empty URL", QUrl()), 0);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldAddNewEntries()
    {
        QCOMPARE(model->add(QUrl("http://example.org/"), "Example Domain", QUrl()), 1);
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->add(QUrl("http://example.com/"), "Example Domain", QUrl()), 1);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Url).toString(),
                 QString("http://example.com/"));
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Visits).toInt(), 1);
        QCOMPARE(model->data(model->index(1, 0), HistoryModel::Url).toString(),
                 QString("http://example.org/"));
        QCOMPARE(model->data(model->index(1, 0), HistoryModel::Visits).toInt(), 1);
    }

    void shouldNotifyWhenAddingNewEntries()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        model->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
    }

    void shouldUpdateExistingEntry()
    {
        QCOMPARE(model->add(QUrl("http://example.org/"), "Example Domain", QUrl()), 1);
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->add(QUrl("http://example.org/"), "Example Domain", QUrl("image://webicon/123")), 2);
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Url).toString(),
                 QString("http://example.org/"));
        QCOMPARE(model->data(model->index(0, 0), HistoryModel::Visits).toInt(), 2);
    }

    void shouldNotifyWhenUpdatingExistingEntry()
    {
        QSignalSpy spyMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QCOMPARE(spyMoved.count(), 0);
        QCOMPARE(spyChanged.count(), 0);
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl("image://webicon/123"));
        QCOMPARE(spyMoved.count(), 0);
        QCOMPARE(spyChanged.count(), 1);
        QList<QVariant> args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QVector<int> roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(HistoryModel::Icon));
        QVERIFY(roles.contains(HistoryModel::Visits));
        model->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QCOMPARE(spyMoved.count(), 0);
        QCOMPARE(spyChanged.count(), 0);
        model->add(QUrl("http://example.org/"), "Example D0ma1n", QUrl("image://webicon/456"));
        QCOMPARE(spyMoved.count(), 1);
        args = spyMoved.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(args.at(4).toInt(), 0);
        QCOMPARE(spyChanged.count(), 1);
        args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 3);
        QVERIFY(roles.contains(HistoryModel::Title));
        QVERIFY(roles.contains(HistoryModel::Icon));
        QVERIFY(roles.contains(HistoryModel::Visits));
    }

    void shouldUpdateTimestamp()
    {
        QDateTime now = QDateTime::currentDateTimeUtc();
        QTest::qWait(1001);
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        model->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        QDateTime ts0 = model->data(model->index(0, 0), HistoryModel::LastVisit).toDateTime();
        QDateTime ts1 = model->data(model->index(1, 0), HistoryModel::LastVisit).toDateTime();
        QVERIFY(ts0 > ts1);
        QVERIFY(ts1 > now);
    }

    void shouldSerializeOnDisk()
    {
        QTemporaryFile tempFile;
        tempFile.open();
        QString fileName = tempFile.fileName();
        delete model;
        model = new HistoryModel(fileName);
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        delete model;
        model = new HistoryModel(fileName);
        QCOMPARE(model->rowCount(), 2);
    }
};

QTEST_MAIN(HistoryModelTests)
#include "tst_HistoryModelTests.moc"
