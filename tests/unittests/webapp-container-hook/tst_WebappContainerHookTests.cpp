/*
 * Copyright 2014 Canonical Ltd.
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
#include <QTemporaryDir>
#include <QProcess>
#include <QtTest/QtTest>

// local
#include "click-hooks/hook-utils.h"


namespace {

    void createFileWithContent(const QString& filename, const QString& content)
    {
        QFile file(filename);
        if (!file.open(QIODevice::ReadWrite))
        {
            return;
        }
        file.write(content.toUtf8());
        file.flush();
    }

    QString readAll(const QString& filename)
    {
        QFile file(filename);
        if (!file.open(QIODevice::ReadOnly))
        {
            return QString();
        }
        return file.readAll();
    }

}


class WebappContainerHookTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void testRemoveVersion_data()
    {
        QTest::addColumn<QString>("appId");
        QTest::addColumn<QString>("appIdNoVersion");
        QTest::newRow("With version") << QString("com.ubuntu.blabla_blabla_0.2") << QString("com.ubuntu.blabla_blabla");
        QTest::newRow("With no version") << QString("com.ubuntu.blabla_blabla") << QString("com.ubuntu.blabla_blabla");
    }
    void testRemoveVersion()
    {
        QFETCH(QString, appId);
        QFETCH(QString, appIdNoVersion);
        QCOMPARE(HookUtils::removeVersionFrom(appId), appIdNoVersion);
    }

    void testClickHookUpdate_data()
    {
        QTest::addColumn<QString>("processedHookFilename");
        QTest::addColumn<QString>("processedHookFileContent");
        QTest::addColumn<QString>("installedHookFilename");
        QTest::addColumn<QString>("installedHookFileContent");
        QTest::addColumn<bool>("shouldBeUpdated");

        QTest::newRow("Invalid installed hook file") << QString("com.ubuntu.blabla_blabla.webapp")
                << QString("[{}]")
                << QString("com.ubuntu.blabla.webapp")
                << QString("[{\"uninstall\": { \"delete-cookies\": true, \"delete-cache\": true } }]")
                << false;
        QTest::newRow("Valid hook file") << QString("com.ubuntu.blabla_blabla.webapp")
                << QString("[{}]")
                << QString("com.ubuntu.blabla_blabla_0.2.webapp")
                << QString("[{\"uninstall\": { \"delete-cookies\": true, \"delete-cache\": true } }]")
                << true;
    }
    void testClickHookUpdate()
    {
        QFETCH(QString, processedHookFilename);
        QFETCH(QString, installedHookFilename);

        QFETCH(QString, processedHookFileContent);
        QFETCH(QString, installedHookFileContent);

        QFETCH(bool, shouldBeUpdated);

        QTemporaryDir processedHookFiledTmpDir;
        QTemporaryDir installedHookFiledTmpDir;

        QVERIFY(!processedHookFilename.isEmpty());
        QString processedFilepath =
                processedHookFiledTmpDir.path() + "/" + processedHookFilename;
        createFileWithContent(processedFilepath, processedHookFileContent);

        QTest::qSleep(1000);

        QVERIFY(!installedHookFilename.isEmpty());
        QString installedHookFilepath =
                installedHookFiledTmpDir.path() + "/" + installedHookFilename;
        createFileWithContent(installedHookFilepath, installedHookFileContent);

        QProcess process;

        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert("WEBAPPCONTAINER_PROCESSED_HOOKS_FOLDER", processedHookFiledTmpDir.path());
        env.insert("WEBAPPCONTAINER_INSTALLED_HOOKS_FOLDER", installedHookFiledTmpDir.path());

        process.start(CLICK_HOOK_EXEC_BIN, QStringList());
        process.waitForFinished();

        if (shouldBeUpdated)
        {
            QCOMPARE(readAll(processedFilepath), readAll(installedHookFilepath));
        }
        else
        {
            QCOMPARE(readAll(processedFilepath), processedHookFileContent);
        }
    }

};

QTEST_MAIN(WebappContainerHookTests)
#include "tst_WebappContainerHookTests.moc"
