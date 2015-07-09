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
#include "domain-utils.h"
#include "history-lastvisitdate-model.h"
#include "history-lastvisitdatelist-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"

class MockHistoryModel : public HistoryModel
{
    Q_OBJECT

public:
    // reimplemented from HistoryModel
    int rowCount(const QModelIndex& parent=QModelIndex()) const
    {
        Q_UNUSED(parent);
        return m_entries.count();
    }

    QVariant data(const QModelIndex& index, int role) const
    {
        if (!index.isValid()) {
            return QVariant();
        }
        const HistoryEntry& entry = m_entries.at(index.row());
        switch (role) {
        case Url:
            return entry.url;
        case Domain:
            return entry.domain;
        case Title:
            return entry.title;
        case Icon:
            return entry.icon;
        case Visits:
            return entry.visits;
        case LastVisit:
            return entry.lastVisit;
        case LastVisitDate:
            return entry.lastVisit.toLocalTime().date();
        case Hidden:
            return entry.hidden;
        default:
            return QVariant();
        }
    }

    void add(const QUrl& url, const QString& title, const QString& domain, const QUrl& icon, const QDateTime& lastVisit)
    {
        HistoryEntry entry;
        entry.url = url;
        entry.domain = domain;
        entry.title = title;
        entry.icon = icon;
        entry.visits = 1;
        entry.lastVisit = lastVisit;
        entry.hidden = false;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
    }

    void removeEntryByUrl(const QUrl& url)
    {
        if (url.isEmpty()) {
            return;
        }

        for (int i = 0; i < m_entries.count(); ++i) {
            if (m_entries.at(i).url == url) {
                beginRemoveRows(QModelIndex(), i, i);
                m_entries.removeAt(i);
                endRemoveRows();
                Q_EMIT rowCountChanged();
            }   
        }
    }

private:
    struct HistoryEntry {
        QUrl url;
        QString domain;
        QString title;
        QUrl icon;
        uint visits;
        QDateTime lastVisit;
        bool hidden;
    };
    QList<HistoryEntry> m_entries;
};

class HistoryLastVisitDateListModelTests : public QObject
{
    Q_OBJECT

private:
    MockHistoryModel* mockHistory;
    HistoryTimeframeModel* timeframe;
    HistoryLastVisitDateListModel* model;

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
        mockHistory = new MockHistoryModel;
        mockHistory->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(mockHistory);
        model = new HistoryLastVisitDateListModel;
        model->setSourceModel(timeframe);
    }

    void cleanup()
    {
        delete model;
        delete timeframe;
        delete mockHistory;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldUpdateLastVsitDateListWhenInsertingEntries()
    {
        QSignalSpy spyRowsInserted(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt1);
        QVERIFY(spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        QList<QVariant> args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt1.date());

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt2);
        QVERIFY(spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(0, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt2.date());

        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt1);
        QVERIFY(spyRowsInserted.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        args = spyDataChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 1);
        QCOMPARE(args.at(1).toModelIndex().row(), 1);
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldUpdateLastVisitDateListWhenChangingTimeFrame()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
        QDateTime dt3 = QDateTime(QDate(1970, 1, 3), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt3);
        QDateTime t0 = QDateTime(QDate(1970, 1, 1), QTime(7, 0, 0));
        QDateTime t1 = QDateTime(QDate(1970, 1, 2), QTime(7, 0, 0));
        QCOMPARE(model->rowCount(), 3);

        timeframe->setEnd(t1);
        QCOMPARE(model->rowCount(), 2);

        timeframe->setStart(t0);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateLastVisitDateListWhenRemovingEntries()
    {
        QSignalSpy spyRowsRemoved(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
        QDateTime dt3 = QDateTime(QDate(1970, 1, 3), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.info/"), "Example Domain", "example.info", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt3);
        QVERIFY(spyRowsRemoved.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        mockHistory->removeEntryByUrl(QUrl("http://example.com/"));
        QVERIFY(spyRowsRemoved.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        mockHistory->removeEntryByUrl(QUrl("http://example.info/"));
        QCOMPARE(spyRowsRemoved.count(), 1);
        QCOMPARE(model->rowCount(), 2);

        mockHistory->removeEntryByUrl(QUrl("http://example.org/"));
        QCOMPARE(spyRowsRemoved.count(), 2);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldUpdateDataWhenMovingEntries()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
 
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        QTest::qWait(100);

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt1);
        QVERIFY(spyRowsMoved.isEmpty());
    }

    void shouldUpdateDataWhenDataChanges()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
 
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt2);
        QVERIFY(spyRowsMoved.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        verifyDataChanged(spyDataChanged, 0);
    }

    void shouldUpdateWhenChangingSourceModel()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
        QDateTime dt3 = QDateTime(QDate(1970, 1, 3), QTime(6, 0, 0));

        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt3);
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(timeframe);
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), (HistoryTimeframeModel*) 0);
        QCOMPARE(model->rowCount(), 0);

        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel(mockHistory);
        timeframe2->setSourceModel(mockHistory);
        model->setSourceModel(timeframe2);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), timeframe2);
        QCOMPARE(model->rowCount(), 3);
    }

    void shouldKeepLastVisitDatesSorted()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
        QDateTime dt3 = QDateTime(QDate(1970, 1, 3), QTime(6, 0, 0));
        QDateTime dt4 = QDateTime(QDate(1970, 1, 4), QTime(6, 0, 0));
        QDateTime dt5 = QDateTime(QDate(1970, 1, 5), QTime(6, 0, 0));
        QDateTime dt6 = QDateTime(QDate(1970, 1, 6), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.edu/"), "Example Domain", "example.edu", QUrl(), dt5);
        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt3);
        mockHistory->add(QUrl("http://example.gov/"), "Example Domain", "example.gov", QUrl(), dt4);
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.web/"), "Example Domain", "example.web", QUrl(), dt6);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        QCOMPARE(model->rowCount(), 6);
        QList<QDate> lastVisitDates;
        lastVisitDates << dt6.date() << dt5.date() << dt4.date() << dt3.date() << dt2.date() << dt1.date();
        for (int i = 0; i < lastVisitDates.count(); ++i) {
            QModelIndex index = model->index(i, 0);
            QDate lastVisitDate = model->data(index, HistoryLastVisitDateListModel::LastVisitDate).toDate();
            HistoryLastVisitDateModel* entries = model->data(index, HistoryLastVisitDateListModel::Entries).value<HistoryLastVisitDateModel*>();
            QVERIFY(!lastVisitDate.isNull());
            QVERIFY(!entries->lastVisitDate().isNull());
            QCOMPARE(lastVisitDate, lastVisitDates.at(i));
            QCOMPARE(entries->lastVisitDate(), lastVisitDate);
        }
    }

    void shouldExposeLastVisitDateModels()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));
        QDateTime dt3 = QDateTime(QDate(1970, 1, 3), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt2);
        mockHistory->add(QUrl("http://example.gov/"), "Example Domain", "example.gov", QUrl(), dt3);
        QCOMPARE(model->rowCount(), 3);

        QModelIndex index = model->index(0, 0);
        QDate lastVisitDate = model->data(index, HistoryLastVisitDateListModel::LastVisitDate).toDate();
        QCOMPARE(lastVisitDate, dt3.date());
        HistoryLastVisitDateModel* entries = model->data(index, HistoryLastVisitDateListModel::Entries).value<HistoryLastVisitDateModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.gov/"));

        index = model->index(1, 0);
        lastVisitDate = model->data(index, HistoryLastVisitDateListModel::LastVisitDate).toDate();
        QCOMPARE(lastVisitDate, dt2.date());
        entries = model->data(index, HistoryLastVisitDateListModel::Entries).value<HistoryLastVisitDateModel*>();
        QCOMPARE(entries->rowCount(), 2);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.net/"));
        QCOMPARE(entries->data(entries->index(1, 0), HistoryModel::Url).toUrl(), QUrl("http://example.org/"));

        index = model->index(2, 0);
        lastVisitDate = model->data(index, HistoryLastVisitDateListModel::LastVisitDate).toDate();
        QCOMPARE(lastVisitDate, dt1.date());
        entries = model->data(index, HistoryLastVisitDateListModel::Entries).value<HistoryLastVisitDateModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), HistoryModel::Url).toUrl(), QUrl("http://example.com/"));
    }

    void shouldReturnData()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        QVERIFY(!model->data(QModelIndex(), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QVERIFY(!model->data(model->index(-1, 0), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QVERIFY(!model->data(model->index(3, 0), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QCOMPARE(model->data(model->index(0, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt1.date());
        HistoryLastVisitDateModel* entries = model->data(model->index(0,0),
                                                 HistoryLastVisitDateListModel::Entries).value<HistoryLastVisitDateModel*>();
        QVERIFY(entries != 0);
        QCOMPARE(entries->rowCount(), 1);
        QVERIFY(!model->data(model->index(0, 0), HistoryLastVisitDateListModel::Entries + 1).isValid());
    }
};

QTEST_MAIN(HistoryLastVisitDateListModelTests)
#include "tst_HistoryLastVisitDateListModelTests.moc"
