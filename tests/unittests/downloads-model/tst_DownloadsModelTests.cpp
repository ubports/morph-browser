/*
 * Copyright 2015-2016 Canonical Ltd.
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

#include <QtCore/QDir>
#include <QtCore/QTemporaryFile>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>
#include "downloads-model.h"

class DownloadsModelTests : public QObject
{
    Q_OBJECT

private:
    DownloadsModel* model;

private Q_SLOTS:
    void init()
    {
        model = new DownloadsModel;
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
        QVERIFY(roleNames.contains("downloadId"));
        QVERIFY(roleNames.contains("url"));
        QVERIFY(roleNames.contains("path"));
        QVERIFY(roleNames.contains("filename"));
        QVERIFY(roleNames.contains("mimetype"));
        QVERIFY(roleNames.contains("complete"));
        QVERIFY(roleNames.contains("paused"));
        QVERIFY(roleNames.contains("error"));
        QVERIFY(roleNames.contains("created"));
    }

    void shouldContainAddedEntries()
    {
        QVERIFY(!model->contains(QStringLiteral("testid")));
        model->add(QStringLiteral("testid"), QUrl(QStringLiteral("http://example.org/")), QStringLiteral("text/html"));
        QVERIFY(model->contains(QStringLiteral("testid")));
    }

    void shouldAddNewEntries()
    {
        QSignalSpy spy(model, SIGNAL(added(QString, QUrl, QString)));

        model->add("testid", QUrl("http://example.org/"), "text/plain");
        QCOMPARE(model->rowCount(), 1);
        QCOMPARE(spy.count(), 1);
        QVariantList args = spy.takeFirst();
        QCOMPARE(args.at(0).toString(), QString("testid"));
        QCOMPARE(args.at(1).toUrl(), QUrl("http://example.org/"));
        QCOMPARE(args.at(2).toString(), QString("text/plain"));

        model->add("testid2", QUrl("http://example.org/pdf"), "application/pdf");
        QCOMPARE(model->rowCount(), 2);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toString(), QString("testid2"));
        QCOMPARE(args.at(1).toUrl(), QUrl("http://example.org/pdf"));
        QCOMPARE(args.at(2).toString(), QString("application/pdf"));
    }

    void shouldRemoveCancelled()
    {
        model->add("testid", QUrl("http://example.org/"), "text/plain");
        model->add("testid2", QUrl("http://example.org/pdf"), "application/pdf");
        model->add("testid3", QUrl("https://example.org/secure.png"), "image/png");
        QCOMPARE(model->rowCount(), 3);

        model->cancelDownload("testid2");
        QCOMPARE(model->rowCount(), 2);

        model->cancelDownload("invalid");
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldCompleteDownloads()
    {
        QSignalSpy spy(model, SIGNAL(completeChanged(QString, bool)));

        model->add("testid", QUrl("http://example.org/"), "text/plain");
        QVERIFY(!model->data(model->index(0, 0), DownloadsModel::Complete).toBool());
        model->setComplete("testid", true);
        QCOMPARE(spy.count(), 1);
        QVariantList args = spy.takeFirst();
        QCOMPARE(args.at(0).toString(), QString("testid"));
        QCOMPARE(args.at(1).toBool(), true);
    }

    void shouldKeepEntriesSortedChronologically()
    {
        model->add("testid", QUrl("http://example.org/"), "text/plain");
        model->add("testid2", QUrl("http://example.org/pdf"), "application/pdf");
        model->add("testid3", QUrl("https://example.org/secure.png"), "image/png");

        QCOMPARE(model->data(model->index(0, 0), DownloadsModel::DownloadId).toString(), QString("testid3"));
        QCOMPARE(model->data(model->index(1, 0), DownloadsModel::DownloadId).toString(), QString("testid2"));
        QCOMPARE(model->data(model->index(2, 0), DownloadsModel::DownloadId).toString(), QString("testid"));
    }

    void shouldReturnData()
    {
        model->add("testid", QUrl("http://example.org/"), "text/plain");
        QVERIFY(!model->data(QModelIndex(), DownloadsModel::DownloadId).isValid());
        QVERIFY(!model->data(model->index(-1, 0), DownloadsModel::DownloadId).isValid());
        QVERIFY(!model->data(model->index(3, 0), DownloadsModel::DownloadId).isValid());
        QCOMPARE(model->data(model->index(0, 0), DownloadsModel::DownloadId).toString(), QString("testid"));
        QCOMPARE(model->data(model->index(0, 0), DownloadsModel::Url).toUrl(), QUrl("http://example.org/"));
        QCOMPARE(model->data(model->index(0, 0), DownloadsModel::Mimetype).toString(), QString("text/plain"));
        QVERIFY(model->data(model->index(0, 0), DownloadsModel::Created).toDateTime() <= QDateTime::currentDateTime());
        QVERIFY(!model->data(model->index(0, 0), DownloadsModel::Complete).toBool());
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
        model = new DownloadsModel;
        model->setDatabasePath(fileName);
        model->add("testid", QUrl("http://example.org/"), "text/plain");
        model->add("testid2", QUrl("http://example.org/pdf"), "application/pdf");
        delete model;
        model = new DownloadsModel;
        model->setDatabasePath(fileName);
        model->fetchMore();
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldCountNumberOfEntries()
    {
        QCOMPARE(model->property("count").toInt(), 0);
        QCOMPARE(model->rowCount(), 0);
        model->add("testid", QUrl("http://example.org/"), "text/plain");
        QCOMPARE(model->property("count").toInt(), 1);
        QCOMPARE(model->rowCount(), 1);
        model->add("testid2", QUrl("http://example.org/pdf"), "application/pdf");
        QCOMPARE(model->property("count").toInt(), 2);
        QCOMPARE(model->rowCount(), 2);
        model->add("testid3", QUrl("https://example.org/secure.png"), "image/png");
        QCOMPARE(model->property("count").toInt(), 3);
        QCOMPARE(model->rowCount(), 3);
    }

};

QTEST_MAIN(DownloadsModelTests)
#include "tst_DownloadsModelTests.moc"
