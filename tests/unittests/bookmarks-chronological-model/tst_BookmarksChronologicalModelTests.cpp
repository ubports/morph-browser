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
#include "bookmarks-model.h"
#include "bookmarks-chronological-model.h"

class BookmarksChronologicalModelTests : public QObject
{
    Q_OBJECT

private:
    BookmarksModel* bookmarks;
    BookmarksChronologicalModel* model;

private Q_SLOTS:
    void init()
    {
        bookmarks = new BookmarksModel;
        bookmarks->setDatabasePath(":memory:");
        model = new BookmarksChronologicalModel;
        model->setSourceModel(bookmarks);
    }

    void cleanup()
    {
        delete model;
        delete bookmarks;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(bookmarks);
        QVERIFY(spy.isEmpty());
        BookmarksModel* bookmarks2 = new BookmarksModel;
        model->setSourceModel(bookmarks2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), bookmarks2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (BookmarksModel*) 0);
        delete bookmarks2;
    }

    void shouldRemainSorted()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl());
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
        QCOMPARE(model->data(model->index(1, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));
    }
};

QTEST_MAIN(BookmarksChronologicalModelTests)
#include "tst_BookmarksChronologicalModelTests.moc"
