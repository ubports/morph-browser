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
#include "bookmarks-model.h"
#include "domain-utils.h"
#include "history-lastvisitdatelist-model.h"
#include "history-model.h"

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
        int index = getEntryIndex(url);
        if (index == -1) {
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
        } else {
            QVector<int> roles;
            roles << LastVisit;
            if (index == 0) {
                HistoryEntry& entry = m_entries.first();
                entry.lastVisit = lastVisit;
            } else {
                beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
                HistoryEntry entry = m_entries.takeAt(index);
                entry.lastVisit = lastVisit;
                m_entries.prepend(entry);
                endMoveRows();
            }
            Q_EMIT dataChanged(this->index(0, 0), this->index(0, 0), roles);
        }
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

    int getEntryIndex(const QUrl& url) const
    {
        for (int i = 0; i < m_entries.count(); ++i) {
                if (m_entries.at(i).url == url) {
                            return i;
                        }
            }
        return -1;
    }

    QList<HistoryEntry> m_entries;
};

class HistoryLastVisitDateListModelTests : public QObject
{
    Q_OBJECT

private:
    MockHistoryModel* mockHistory;
    HistoryLastVisitDateListModel* model;
    BookmarksModel* bookmarks;

private Q_SLOTS:
    void init()
    {
        mockHistory = new MockHistoryModel;
        mockHistory->setDatabasePath(":memory:");
        model = new HistoryLastVisitDateListModel;
        model->setSourceModel(QVariant::fromValue(mockHistory));
        bookmarks = new BookmarksModel;
        bookmarks->setDatabasePath(":memory:");
    }

    void cleanup()
    {
        delete model;
        delete mockHistory;
        delete bookmarks;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldUpdateLastVisitDateListWhenInsertingEntries()
    {
        QSignalSpy spyRowsInserted(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        qRegisterMetaType<QVector<int> >();

        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt1);
        QCOMPARE(spyRowsInserted.count(), 2);
        QList<QVariant> args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(1, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt1.date());

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt2);
        QCOMPARE(spyRowsInserted.count(), 1);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(model->rowCount(), 3);
        QCOMPARE(model->data(model->index(1, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt2.date());

        mockHistory->add(QUrl("http://example.net/"), "Example Domain", "example.net", QUrl(), dt1);
        QVERIFY(spyRowsInserted.isEmpty());
        QCOMPARE(model->rowCount(), 3);
    }

    void shouldBeEmptyAfterRemovingAllEntries() {
        QSignalSpy spyRowsInserted(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        QSignalSpy spyRowsRemoved(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        QCOMPARE(spyRowsInserted.count(), 3);
        QCOMPARE(model->rowCount(), 3);

        mockHistory->removeEntryByUrl(QUrl("http://example.com/"));
        mockHistory->removeEntryByUrl(QUrl("http://example.org/"));
        QCOMPARE(spyRowsRemoved.count(), 3);
        QCOMPARE(model->rowCount(), 0);
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
        QCOMPARE(model->rowCount(), 4);

        mockHistory->removeEntryByUrl(QUrl("http://example.com/"));
        QVERIFY(spyRowsRemoved.isEmpty());
        QCOMPARE(model->rowCount(), 4);

        mockHistory->removeEntryByUrl(QUrl("http://example.info/"));
        QCOMPARE(spyRowsRemoved.count(), 1);
        QCOMPARE(model->rowCount(), 3);

        mockHistory->removeEntryByUrl(QUrl("http://example.org/"));
        QCOMPARE(spyRowsRemoved.count(), 2);
        QCOMPARE(model->rowCount(), 2);
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
        QSignalSpy spyRowsRemoved(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        QDateTime dt2 = QDateTime(QDate(1970, 1, 2), QTime(6, 0, 0));

        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        mockHistory->add(QUrl("http://example.org/"), "Example Domain", "example.org", QUrl(), dt2);
        QCOMPARE(model->rowCount(), 3);
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt2);
        QCOMPARE(model->rowCount(), 2);
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
        QCOMPARE(model->rowCount(), 4);

        model->setSourceModel(QVariant::fromValue(mockHistory));
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->rowCount(), 4);

        QTest::ignoreMessage(QtWarningMsg, "Only QAbstractItemModel-derived instances and null are allowed as source models");
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 1);
        QVERIFY(!model->sourceModel().isValid());
        QCOMPARE(model->rowCount(), 0);

        MockHistoryModel mockHistory2;
        model->setSourceModel(QVariant::fromValue(&mockHistory2));
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel().value<MockHistoryModel*>(), &mockHistory2);
        QCOMPARE(model->rowCount(), 0);

        QTest::ignoreMessage(QtWarningMsg, "Only QAbstractItemModel-derived instances and null are allowed as source models");
        model->setSourceModel(QVariant::fromValue(QString("not a model")));
        QCOMPARE(spy.count(), 3);
        QVERIFY(!model->sourceModel().isValid());
        QCOMPARE(model->rowCount(), 0);

        QTest::ignoreMessage(QtWarningMsg, "No results will be returned because the sourceModel does not have a role named \"lastVisitDate\"");
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        model->setSourceModel(QVariant::fromValue(bookmarks));
        QCOMPARE(model->rowCount(), 0);

        spy.clear();
        model->setSourceModel(QVariant());
        QCOMPARE(spy.count(), 1);
        QVERIFY(model->sourceModel().isNull());
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
        QCOMPARE(model->rowCount(), 7);
        QList<QDate> lastVisitDates;
        lastVisitDates << dt6.date() << dt5.date() << dt4.date() << dt3.date() << dt2.date() << dt1.date();
        QModelIndex defaultIndex = model->index(0, 0);
        QDate defaultDate = model->data(defaultIndex, HistoryLastVisitDateListModel::LastVisitDate).toDate();
        QVERIFY(defaultDate.isNull());
        for (int i = 1; i < lastVisitDates.count(); ++i) {
            QModelIndex index = model->index(i, 0);
            QDate lastVisitDate = model->data(index, HistoryLastVisitDateListModel::LastVisitDate).toDate();
            QVERIFY(!lastVisitDate.isNull());
            QCOMPARE(lastVisitDate, lastVisitDates.at(i-1));
        }
    }

    void shouldReturnData()
    {
        QDateTime dt1 = QDateTime(QDate(1970, 1, 1), QTime(6, 0, 0));
        mockHistory->add(QUrl("http://example.com/"), "Example Domain", "example.com", QUrl(), dt1);
        QVERIFY(!model->data(QModelIndex(), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QVERIFY(!model->data(model->index(-1, 0), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QVERIFY(!model->data(model->index(3, 0), HistoryLastVisitDateListModel::LastVisitDate).isValid());
        QCOMPARE(model->data(model->index(0, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), QDate());
        QCOMPARE(model->data(model->index(1, 0), HistoryLastVisitDateListModel::LastVisitDate).toDate(), dt1.date());
        QVERIFY(!model->data(model->index(1, 0), HistoryLastVisitDateListModel::LastVisitDate + 1).isValid());
    }
};

QTEST_MAIN(HistoryLastVisitDateListModelTests)
#include "tst_HistoryLastVisitDateListModelTests.moc"
