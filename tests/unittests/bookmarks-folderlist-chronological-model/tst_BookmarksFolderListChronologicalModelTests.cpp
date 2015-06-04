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
#include "bookmarks-folder-model.h"
#include "bookmarks-folderlist-model.h"
#include "bookmarks-folderlist-chronological-model.h"

class BookmarksFolderListChronologicalModelTests : public QObject
{
    Q_OBJECT

private:
    BookmarksModel* bookmarks;
    BookmarksFolderListModel* folderlist;
    BookmarksFolderListChronologicalModel* model;

private Q_SLOTS:
    void init()
    {
        bookmarks = new BookmarksModel;
        bookmarks->setDatabasePath(":memory:");
        folderlist = new BookmarksFolderListModel;
        folderlist->setSourceModel(bookmarks);
        model = new BookmarksFolderListChronologicalModel;
        model->setSourceModel(folderlist);
    }

    void cleanup()
    {
        delete model;
        delete folderlist;
        delete bookmarks;
    }

    void shouldHaveInitiallyOnlyDefaultFolder()
    {
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksFolderListModel::Folder).toString(), QString(""));
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(folderlist);
        QVERIFY(spy.isEmpty());
        BookmarksFolderListModel* folderlist2 = new BookmarksFolderListModel;
        model->setSourceModel(folderlist2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), folderlist2);
        model->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), (BookmarksFolderListModel*) 0);
        delete folderlist2;
    }

    void shouldRemainSorted()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        QTest::qWait(1001);
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "AnotherFolder");
        QCOMPARE(model->data(model->index(0, 0), BookmarksFolderListModel::Folder).toString(), QString("AnotherFolder"));
        QCOMPARE(model->data(model->index(1, 0), BookmarksFolderListModel::Folder).toString(), QString("SampleFolder"));
    }

    void shouldNotRemoveFolder() {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        QTest::qWait(1001);
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "AnotherFolder");
        QSignalSpy spy(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        bookmarks->remove(QUrl("http://ubuntu.com/"));
        QVERIFY(spy.isEmpty());
    }
};

QTEST_MAIN(BookmarksFolderListChronologicalModelTests)
#include "tst_BookmarksFolderListChronologicalModelTests.moc"
