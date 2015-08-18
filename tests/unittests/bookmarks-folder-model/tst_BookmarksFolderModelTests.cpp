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


class BookmarksFolderModelTests : public QObject
{
    Q_OBJECT

private:
    BookmarksModel* bookmarks;
    BookmarksFolderModel* model;

private Q_SLOTS:
    void init()
    {
        bookmarks = new BookmarksModel;
        bookmarks->setDatabasePath(":memory:");
        model = new BookmarksFolderModel;
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
    }

    void shouldNotifyWhenChangingFolder()
    {
        QSignalSpy spy(model, SIGNAL(folderChanged()));
        model->setFolder(QString());
        QVERIFY(spy.isEmpty());
        model->setFolder(QString(""));
        QVERIFY(spy.isEmpty());
        model->setFolder("SampleFolder");
        QCOMPARE(spy.count(), 1);
    }

    void shouldMatchAllNotInFoldersWhenNoFolderSet()
    {
        bookmarks->add(QUrl("http://example.org"), "Example Domain", QUrl(), "");
        bookmarks->add(QUrl("http://example.com"), "Example Domain", QUrl(), "SampleFolder");
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldFilterOutNonMatchingFolders()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain Org", QUrl(), "");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain Com", QUrl(), "SampleFolder01");
        bookmarks->add(QUrl("http://example.net/"), "Example Domain Net", QUrl("http://example.net/icon.png"), "SampleFolder02");
        model->setFolder("");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));
        QCOMPARE(model->get(0).value("url").toUrl(), QUrl("http://example.org/"));
        model->setFolder("SampleFolder01");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.com/"));
        QCOMPARE(model->get(0).value("title").toString(), QString("Example Domain Com"));
        model->setFolder("SampleFolder02");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.net/"));
        QCOMPARE(model->get(0).value("icon").toUrl(), QUrl("http://example.net/icon.png"));
        model->setFolder("AnotherFolder");
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldMatchCaseSensitiveFolderName()
    {
        bookmarks->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "SAMPLE");
        bookmarks->add(QUrl("http://example.com/"), "Example Domain", QUrl(), "sample");
        model->setFolder("SAMPLE");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));
        model->setFolder("sample");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.com/"));
        model->setFolder("SaMpLe");
        QCOMPARE(model->rowCount(), 0);
    }
};

QTEST_MAIN(BookmarksFolderModelTests)
#include "tst_BookmarksFolderModelTests.moc"
