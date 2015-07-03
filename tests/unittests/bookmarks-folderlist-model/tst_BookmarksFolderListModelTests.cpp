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
#include <QtCore/QObject>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "bookmarks-model.h"
#include "bookmarks-folder-model.h"
#include "bookmarks-folderlist-model.h"

class BookmarksFolderListModelTests : public QObject
{
    Q_OBJECT

private:
    BookmarksModel* bookmarks;
    BookmarksFolderListModel* model;

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
        bookmarks = new BookmarksModel;
        bookmarks->setDatabasePath(":memory:");
        model = new BookmarksFolderListModel;
        model->setSourceModel(bookmarks);
    }

    void cleanup()
    {
        delete model;
        delete bookmarks;
    }

    void shouldHaveInitiallyOnlyDefaultFolder()
    {
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksFolderListModel::Folder).toString(), QString(""));
    }

    void shouldUpdateFolderListWhenInsertingEntries()
    {
        QSignalSpy spyRowsInserted(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        QVERIFY(!spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        QList<QVariant> args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(model->data(model->index(1, 0), BookmarksFolderListModel::Folder).toString(), QString("SampleFolder"));

        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "AnotherFolder");
        QVERIFY(!spyDataChanged.isEmpty());
        QCOMPARE(spyRowsInserted.count(), 1);
        args = spyRowsInserted.takeFirst();
        QCOMPARE(args.at(1).toInt(), 1);
        QCOMPARE(args.at(2).toInt(), 1);
        QCOMPARE(model->rowCount(), 3);
        QCOMPARE(model->data(model->index(1, 0), BookmarksFolderListModel::Folder).toString(), QString("AnotherFolder"));

        bookmarks->add(QUrl("http://example.org/test.html"), "Test page", QUrl(), "SampleFolder");
        QVERIFY(spyRowsInserted.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        QCOMPARE(model->rowCount(), 3);
    }

    void shouldCreateNewEmptyFolder()
    {
        model->createNewFolder("SampleFolder");
        QCOMPARE(model->rowCount(), 2);
        QModelIndex index = model->index(1, 0);
        QCOMPARE(model->data(index, BookmarksFolderListModel::Folder).toString(), QString("SampleFolder"));
        BookmarksFolderModel* entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QCOMPARE(entries->rowCount(), 0);
    }

    void shouldNotUpdateFolderListWhenRemovingEntries()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "AnotherFolder");
        bookmarks->add(QUrl("http://example.org/test"), "Example Domain", QUrl(), "SampleFolder");
        QCOMPARE(model->rowCount(), 3);

        bookmarks->remove(QUrl("http://example.org/test"));
        QCOMPARE(model->rowCount(), 3);

        bookmarks->remove(QUrl("http://example.org/"));
        QCOMPARE(model->rowCount(), 3);
        QModelIndex index = model->index(2, 0);
        QString folder = model->data(index, BookmarksFolderListModel::Folder).toString();
        QCOMPARE(folder, QString("SampleFolder"));
        BookmarksFolderModel* entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QVERIFY(entries != 0);
        QCOMPARE(entries->rowCount(), 0);
    }

    void shouldUpdateDataWhenMovingEntries()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "AnotherFolder");
        QTest::qWait(100);

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        bookmarks->add(QUrl("http://example.org/test"), "Example Domain", QUrl(), "SampleFolder");
        QVERIFY(spyRowsMoved.isEmpty());
    }

    void shouldUpdateDataWhenDataChanges()
    {
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "AnotherFolder");

        QSignalSpy spyRowsMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spyDataChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        bookmarks->add(QUrl("http://example.org/foobar"), "Example Domain", QUrl(), "SampleFolder");
        QVERIFY(spyRowsMoved.isEmpty());
        QVERIFY(!spyDataChanged.isEmpty());
        verifyDataChanged(spyDataChanged, 2);
    }

    void shouldUpdateWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "AnotherFolder");
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(bookmarks);
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->rowCount(), 3);

        model->setSourceModel(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), (BookmarksModel*) 0);
        QCOMPARE(model->rowCount(), 0);

        BookmarksModel* bookmarks2 = new BookmarksModel();
        model->setSourceModel(bookmarks2);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(model->sourceModel(), bookmarks2);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldKeepFolderSorted()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "Folder02");
        bookmarks->add(QUrl("http://www.gogle.com/lawnmower"), "Gogle Lawn Mower", QUrl(), "Folder03");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "Folder01");
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "Folder04");
        bookmarks->add(QUrl("http://www.gogle.com/mail"), "Gogle Mail", QUrl(), "Folder03");
        bookmarks->add(QUrl("https://mail.gogle.com/"), "Gogle Mail", QUrl(), "Folder03");
        QCOMPARE(model->rowCount(), 5);
        QStringList folders;
        folders << "" << "Folder01" << "Folder02" << "Folder03" << "Folder04";
        for (int i = 0; i < folders.count(); ++i) {
            QModelIndex index = model->index(i, 0);
            QString folder = model->data(index, BookmarksFolderListModel::Folder).toString();
            BookmarksFolderModel* entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
            QVERIFY(!folder.isNull());
            QCOMPARE(folder, folders.at(i));
            QCOMPARE(entries->folder(), folder);
        }
    }

    void shouldExposeFolderModels()
    {
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "AnotherFolder");
        QTest::qWait(100);
        bookmarks->add(QUrl("http://example.org/test.html"), "Test Page", QUrl(), "AnotherFolder");
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);

        QModelIndex index = model->index(0, 0);
        QString folder = model->data(index, BookmarksFolderListModel::Folder).toString();
        QCOMPARE(folder, QString(""));
        BookmarksFolderModel* entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://ubuntu.com/"));

        index = model->index(1, 0);
        folder = model->data(index, BookmarksFolderListModel::Folder).toString();
        QCOMPARE(folder, QString("AnotherFolder"));
        entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QCOMPARE(entries->rowCount(), 2);
        QCOMPARE(entries->data(entries->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/test.html"));
        QCOMPARE(entries->data(entries->index(1, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));

        index = model->index(2, 0);
        folder = model->data(index, BookmarksFolderListModel::Folder).toString();
        QCOMPARE(folder, QString("SampleFolder"));
        entries = model->data(index, BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.com/"));
    }

    void shouldReturnData()
    {
        QDateTime now = QDateTime::currentDateTimeUtc();
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SampleFolder");
        QVERIFY(!model->data(QModelIndex(), BookmarksFolderListModel::Folder).isValid());
        QVERIFY(!model->data(model->index(-1, 0), BookmarksFolderListModel::Folder).isValid());
        QVERIFY(!model->data(model->index(3, 0), BookmarksFolderListModel::Folder).isValid());
        QCOMPARE(model->data(model->index(1, 0), BookmarksFolderListModel::Folder).toString(), QString("SampleFolder"));
        BookmarksFolderModel* entries = model->data(model->index(1, 0), BookmarksFolderListModel::Entries).value<BookmarksFolderModel*>();
        QVERIFY(entries != 0);
        QCOMPARE(entries->rowCount(), 1);
        QVERIFY(!model->data(model->index(1, 0), BookmarksFolderListModel::Entries + 1).isValid());
    }

    void shouldReturnDataByIndex()
    {
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "SampleFolder");
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "AnotherFolder");
        bookmarks->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);
        QCOMPARE(model->indexOf("AnotherFolder"), 1);
        QVariantMap folderMap = model->get(3);
        QVERIFY(folderMap.isEmpty());
        folderMap = model->get(1);
        QCOMPARE(folderMap.value("folder").toString(), QString("AnotherFolder"));
        BookmarksFolderModel* entries = folderMap.value("entries").value<BookmarksFolderModel*>();
        QCOMPARE(entries->rowCount(), 1);
        QCOMPARE(entries->data(entries->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));
    }
};

QTEST_MAIN(BookmarksFolderListModelTests)
#include "tst_BookmarksFolderListModelTests.moc"
