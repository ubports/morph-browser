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
#include <QtCore/QDir>
#include <QtCore/QTemporaryFile>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "media-access-model.h"

#define VTRUE QVariant(true)
#define VFALSE QVariant(false)
#define VNULL QVariant()

class MediaAccessModelTests : public QObject
{
    Q_OBJECT

private:
    MediaAccessModel* model;

private Q_SLOTS:
    void init()
    {
        model = new MediaAccessModel;
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

    void shouldAddEntryWhenSettingNewOriginWithAnyMediaSet_data()
    {
            QTest::addColumn<QString>("origin");
            QTest::addColumn<QVariant>("audio");
            QTest::addColumn<QVariant>("video");
            QTest::addColumn<int>("newRows");
            QTest::newRow("a:true,v:true") << "1" << VTRUE << VTRUE << 1;
            QTest::newRow("a:true,v:false") << "2" << VTRUE << VFALSE << 1;
            QTest::newRow("a:false,v:true") << "3" << VFALSE << VFALSE << 1;
            QTest::newRow("a:false,v:false") << "4" << VFALSE << VFALSE << 1;
            QTest::newRow("a:true") << "5" << VTRUE << VNULL << 1;
            QTest::newRow("v:true") << "6" << VNULL << VTRUE << 1;
            QTest::newRow("a:false") << "7" << VFALSE << VNULL << 1;
            QTest::newRow("v:false") << "8" << VNULL << VFALSE << 1;
            QTest::newRow("none") << "9" << VNULL << VNULL << 0;
    }

    void shouldAddEntryWhenSettingNewOriginWithAnyMediaSet()
    {
        QFETCH(QString, origin);
        QFETCH(QVariant, audio);
        QFETCH(QVariant, video);
        QFETCH(int, newRows);
        model->set(origin, audio, video);
        QCOMPARE(model->rowCount(), newRows);
    }

    void shouldNotifyWhenAddingNewEntries()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        model->set("example.org", VTRUE, VTRUE);
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        // From here on we are only setting over the same origin so no new rows
        // should be added
        model->set("example.org", VTRUE, VTRUE);
        QCOMPARE(spy.count(), 0);
        model->set("example.org", VFALSE, VFALSE);
        QCOMPARE(spy.count(), 0);
    }

    void shouldUpdateExistingEntry_data()
    {
        QTest::addColumn<QVariant>("baseAudio");
        QTest::addColumn<QVariant>("baseVideo");
        QTest::addColumn<QVariant>("audio");
        QTest::addColumn<QVariant>("video");
        QTest::addColumn<QVariant>("newAudio");
        QTest::addColumn<QVariant>("newVideo");
        QTest::addColumn<QString>("permissionsSet");
        QTest::newRow("both true") << VFALSE << VFALSE << VTRUE << VTRUE << VTRUE << VTRUE << "av";
        QTest::newRow("only audio false") << VTRUE << VTRUE << VFALSE << VNULL << VFALSE << VTRUE << "av";
        QTest::newRow("only audio true") << VFALSE << VFALSE << VTRUE << VNULL << VTRUE << VFALSE << "av";
        QTest::newRow("only video false") << VTRUE << VTRUE << VNULL << VFALSE << VTRUE << VFALSE << "av";
        QTest::newRow("only video true") << VFALSE << VFALSE << VNULL << VTRUE << VFALSE << VTRUE << "av";
        QTest::newRow("both false") << VTRUE << VTRUE << VFALSE << VFALSE << VFALSE << VFALSE << "av";
        QTest::newRow("audio unset") << VNULL << VTRUE << VNULL << VFALSE << VNULL << VFALSE << "v";
        QTest::newRow("video unset") << VTRUE << VNULL << VFALSE << VNULL << VFALSE << VNULL << "a";
    }

    void shouldUpdateExistingEntry()
    {
        QFETCH(QVariant, baseAudio);
        QFETCH(QVariant, baseVideo);
        QFETCH(QVariant, audio);
        QFETCH(QVariant, video);
        QFETCH(QVariant, newAudio);
        QFETCH(QVariant, newVideo);
        QFETCH(QString, permissionsSet);
        model->set("example.org", baseAudio, baseVideo);
        model->set("example.org", audio, video);
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Audio), newAudio);
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Video), newVideo);
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::PermissionsSet).toString(), permissionsSet);
    }

    void shouldModifyEntryAndNotifyChangedWhenUnsettingOnlyOnePermission()
    {
        QSignalSpy spyChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QList<QVariant> args;
        QVector<int> roles;

        model->set("example.com", QVariant(true), QVariant(true));
        spyChanged.clear();

        model->unset("example.com", true, false);
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Audio), QVariant());
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Video), QVariant(true));
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::PermissionsSet), QVariant("v"));
        QCOMPARE(spyChanged.count(), 1);
        args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(MediaAccessModel::Audio));
        QVERIFY(roles.contains(MediaAccessModel::PermissionsSet));

        model->set("example.com", QVariant(true), QVariant(true));
        spyChanged.clear();

        model->unset("example.com", false, true);
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Audio), QVariant(true));
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::Video), QVariant());
        QCOMPARE(model->data(model->index(0, 0), MediaAccessModel::PermissionsSet), QVariant("a"));
        QCOMPARE(spyChanged.count(), 1);
        args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(MediaAccessModel::Video));
        QVERIFY(roles.contains(MediaAccessModel::PermissionsSet));
    }

    void shouldRemoveEntryAndNotifyRemovalWhenUnsettingBothPermissions()
    {
        QSignalSpy spy(model, SIGNAL(rowsRemoved(QModelIndex,int,int)));
        QList<QVariant> args;

        model->set("example.com", QVariant(true), QVariant(true));
        model->unset("example.com", true, true);
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->set("example.com", QVariant(), QVariant(true));
        model->unset("example.com", false, true);
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);

        model->set("example.com", QVariant(true), QVariant());
        model->unset("example.com", true, false);
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 0);
        QCOMPARE(args.at(2).toInt(), 0);
    }

    void shouldNotifyWhenUpdatingExistingEntry()
    {
        model->set("example.com", QVariant(true), QVariant(true));
        QSignalSpy spyChanged(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));

        model->set("example.com", QVariant(false), QVariant(false));
        QCOMPARE(spyChanged.count(), 1);
        QList<QVariant> args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QVector<int> roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(MediaAccessModel::Audio));
        QVERIFY(roles.contains(MediaAccessModel::Video));

        model->set("example.com", QVariant(true), QVariant());
        QCOMPARE(spyChanged.count(), 1);
        args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(MediaAccessModel::Audio));

        model->set("example.com", QVariant(), QVariant(true));
        QCOMPARE(spyChanged.count(), 1);
        args = spyChanged.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QVERIFY(roles.size() >= 2);
        QVERIFY(roles.contains(MediaAccessModel::Video));
    }

    void shouldGetPermissions_data()
    {
        QTest::addColumn<QVariant>("audio");
        QTest::addColumn<QVariant>("video");
        QTest::newRow("a:true,v:true")  << VTRUE << VTRUE;
        QTest::newRow("a:true,v:false")  << VTRUE << VFALSE;
        QTest::newRow("a:false,v:true")  << VFALSE << VFALSE;
        QTest::newRow("a:false,v:false")  << VFALSE << VFALSE;
        QTest::newRow("a:true")  << VTRUE << VNULL;
        QTest::newRow("v:true")  << VNULL << VTRUE;
        QTest::newRow("a:false")  << VFALSE << VNULL;
        QTest::newRow("v:false")  << VNULL << VFALSE;
        QTest::newRow("none")  << VNULL << VNULL;
    }

    void shouldGetPermissions()
    {
        QFETCH(QVariant, audio);
        QFETCH(QVariant, video);
        model->set("example.org", audio, video);
        QVariantMap item = qvariant_cast<QVariantMap>(model->get("example.org"));
        QCOMPARE(item.value("audio"), audio);
        QCOMPARE(item.value("video"), video);
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
};

QTEST_MAIN(MediaAccessModelTests)
#include "tst_MediaAccessModelTests.moc"
