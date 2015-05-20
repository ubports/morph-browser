/*
 * Copyright 2013-2014 Canonical Ltd.
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
#include "bookmarks-model.h"

class BookmarksModelTests : public QObject
{
    Q_OBJECT

private:
    BookmarksModel* model;

private Q_SLOTS:
    void init()
    {
        model = new BookmarksModel;
        model->setDatabasePath(":memory:");
    }

    void cleanup()
    {
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldExposeRoleNames()
    {
        QList<QByteArray> roleNames = model->roleNames().values();
        QVERIFY(roleNames.contains("url"));
        QVERIFY(roleNames.contains("title"));
        QVERIFY(roleNames.contains("icon"));
        QVERIFY(roleNames.contains("created"));
        QVERIFY(roleNames.contains("folder"));
    }

    void shouldAddNewEntries()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(QModelIndex, int, int)));

        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(spy.count(), 1);
        QVariantList args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->add(QUrl("http://wikipedia.org/"), "Wikipedia", QUrl(), "");
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);
        QVERIFY(spy.isEmpty());
    }

    void shouldRemoveEntries()
    {
        QSignalSpy spy(model, SIGNAL(rowsRemoved(QModelIndex, int, int)));
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        model->add(QUrl("http://wikipedia.org/"), "Wikipedia", QUrl(), "");
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        QCOMPARE(model->rowCount(), 3);
        QVERIFY(spy.isEmpty());

        model->remove(QUrl("http://ubuntu.com/"));
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(spy.count(), 1);
        QVariantList args = spy.takeFirst();
        // Model is chronologically sorted so deleting the last entry added
        // actually deletes the first item in the model
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->remove(QUrl("http://ubuntu.com/"));
        QCOMPARE(model->rowCount(), 2);
        QVERIFY(spy.isEmpty());
    }

    void shouldContainEntries()
    {
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");

        QVERIFY(model->contains(QUrl("http://ubuntu.com/")));
        QVERIFY(!model->contains(QUrl("http://wikipedia.org/")));
    }

    void shouldKeepEntriesSortedChronologically()
    {
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        model->add(QUrl("http://wikipedia.org/"), "Wikipedia", QUrl(), "");
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");

        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://example.org/"));
        QCOMPARE(model->data(model->index(1, 0), BookmarksModel::Url).toUrl(), QUrl("http://wikipedia.org/"));
        QCOMPARE(model->data(model->index(2, 0), BookmarksModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
    }

    void shouldReturnData()
    {
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl("image://webicon/123"), "SampleFolder");
        QVERIFY(!model->data(QModelIndex(), BookmarksModel::Url).isValid());
        QVERIFY(!model->data(model->index(-1, 0), BookmarksModel::Url).isValid());
        QVERIFY(!model->data(model->index(3, 0), BookmarksModel::Url).isValid());
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Title).toString(), QString("Ubuntu"));
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Icon).toUrl(), QUrl("image://webicon/123"));
        QVERIFY(model->data(model->index(0, 0), BookmarksModel::Created).toDateTime() <= QDateTime::currentDateTime());
        QCOMPARE(model->data(model->index(0, 0), BookmarksModel::Folder).toString(), QString("SampleFolder"));
        QVERIFY(!model->data(model->index(0, 0), BookmarksModel::Folder + 1).isValid());
    }

    void shouldReturnDatabasePath()
    {
        QCOMPARE(model->databasePath(), QString(":memory:"));
    }

    void shouldNotifyWhenSettingDatabasePath()
    {
        QSignalSpy spyPath(model, SIGNAL(databasePathChanged()));
        QSignalSpy spyReset(model, SIGNAL(modelReset()));

        model->setDatabasePath(":memory:");
        QVERIFY(spyPath.isEmpty());
        QVERIFY(spyReset.isEmpty());

        model->setDatabasePath("");
        QCOMPARE(spyPath.count(), 1);
        QCOMPARE(spyReset.count(), 1);
        QCOMPARE(model->databasePath(), QString(":memory:"));
    }

    void shouldSerializeOnDisk()
    {
        QTemporaryFile tempFile;
        tempFile.open();
        QString fileName = tempFile.fileName();
        delete model;
        model = new BookmarksModel;
        model->setDatabasePath(fileName);
        model->add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        model->add(QUrl("http://ubuntu.com/"), "Ubuntu", QUrl(), "");
        delete model;
        model = new BookmarksModel;
        model->setDatabasePath(fileName);
        QCOMPARE(model->rowCount(), 2);
    }
};

QTEST_MAIN(BookmarksModelTests)
#include "tst_BookmarksModelTests.moc"
