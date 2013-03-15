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
#include <QtTest/QtTest>

// local
#include "commandline-parser.h"

class CommandLineParserTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void shouldDisplayHelp_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<bool>("help");
        QString BINARY("webbrowser-app");
        QString URL("http://ubuntu.com");
        QTest::newRow("no switch") << (QStringList() << BINARY) << false;
        QTest::newRow("no switch with URL") << (QStringList() << BINARY << URL) << false;
        QTest::newRow("short switch only") << (QStringList() << BINARY << "-h") << true;
        QTest::newRow("long switch only") << (QStringList() << BINARY << "--help") << true;
        QTest::newRow("short switch before URL") << (QStringList() << BINARY << "-h" << URL) << true;
        QTest::newRow("long switch before URL") << (QStringList() << BINARY << "--help" << URL) << true;
        QTest::newRow("short switch after URL") << (QStringList() << BINARY << URL << "-h") << true;
        QTest::newRow("long switch after URL") << (QStringList() << BINARY << URL << "--help") << true;
        QTest::newRow("short switch typo") << (QStringList() << BINARY << "-j") << false;
        QTest::newRow("long switch typo") << (QStringList() << BINARY << "--helo") << false;
        QTest::newRow("short switch long") << (QStringList() << BINARY << "--h") << false;
        QTest::newRow("long switch short") << (QStringList() << BINARY << "-help") << false;
        QTest::newRow("short switch uppercase") << (QStringList() << BINARY << "-H") << false;
        QTest::newRow("long switch uppercase") << (QStringList() << BINARY << "--HELP") << false;
    }

    void shouldDisplayHelp()
    {
        QFETCH(QStringList, args);
        QFETCH(bool, help);
        QCOMPARE(CommandLineParser(args).help(), help);
    }

    void shouldBeChromeless_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<bool>("chromeless");
        QString BINARY("webbrowser-app");
        QString URL("http://ubuntu.com");
        QTest::newRow("no switch") << (QStringList() << BINARY) << false;
        QTest::newRow("switch only") << (QStringList() << BINARY << "--chromeless") << true;
        QTest::newRow("switch before URL") << (QStringList() << BINARY << "--chromeless" << URL) << true;
        QTest::newRow("switch after URL") << (QStringList() << BINARY << URL << "--chromeless") << true;
        QTest::newRow("switch typo") << (QStringList() << BINARY << "--chromeles") << false;
        QTest::newRow("switch uppercase") << (QStringList() << BINARY << "--CHROMELESS") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "-h" << "--chromeless") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "--help" << "--chromeless") << false;
    }

    void shouldBeChromeless()
    {
        QFETCH(QStringList, args);
        QFETCH(bool, chromeless);
        QCOMPARE(CommandLineParser(args).chromeless(), chromeless);
    }

    void shouldBeFullscreen_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<bool>("fullscreen");
        QString BINARY("webbrowser-app");
        QString URL("http://ubuntu.com");
        QTest::newRow("no switch") << (QStringList() << BINARY) << false;
        QTest::newRow("switch only") << (QStringList() << BINARY << "--fullscreen") << true;
        QTest::newRow("switch before URL") << (QStringList() << BINARY << "--fullscreen" << URL) << true;
        QTest::newRow("switch after URL") << (QStringList() << BINARY << URL << "--fullscreen") << true;
        QTest::newRow("switch typo") << (QStringList() << BINARY << "--fulscreen") << false;
        QTest::newRow("switch uppercase") << (QStringList() << BINARY << "--FULLSCREEN") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "-h" << "--fullscreen") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "--help" << "--fullscreen") << false;
    }

    void shouldBeFullscreen()
    {
        QFETCH(QStringList, args);
        QFETCH(bool, fullscreen);
        QCOMPARE(CommandLineParser(args).fullscreen(), fullscreen);
    }

    void shouldRecordURL_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<QUrl>("url");
        QString BINARY("webbrowser-app");
        QString DEFAULT("http://www.ubuntu.com");
        QString URL1("http://example.org");
        QString URL2("http://example.com");
        QTest::newRow("no URL") << (QStringList() << BINARY) << QUrl(DEFAULT);
        QTest::newRow("no URL with switches") << (QStringList() << BINARY << "--chromeless" << "--fullscreen") << QUrl(DEFAULT);
        QTest::newRow("help precludes URL") << (QStringList() << BINARY << "-h" << URL1) << QUrl(DEFAULT);
        QTest::newRow("help precludes URL") << (QStringList() << BINARY << "--help" << URL1) << QUrl(DEFAULT);
        QTest::newRow("one URL") << (QStringList() << BINARY << URL1) << QUrl(URL1);
        QTest::newRow("several URLs") << (QStringList() << BINARY << URL1 << URL2) << QUrl(URL1);
        QTest::newRow("missing scheme") << (QStringList() << BINARY << "ubuntu.com") << QUrl("http://ubuntu.com");
        QTest::newRow("malformed URL") << (QStringList() << BINARY << "@") << QUrl(DEFAULT);
        QTest::newRow("malformed URL") << (QStringList() << BINARY << "@" << URL1) << QUrl(URL1);
        QTest::newRow("homepage switch only") << (QStringList() << BINARY << "--homepage=http://example.com") << QUrl("http://example.com");
        QTest::newRow("homepage switch overrides URL") << (QStringList() << BINARY << "--homepage=http://example.com" << "http://ubuntu.com") << QUrl("http://example.com");
        QTest::newRow("empty homepage switch") << (QStringList() << BINARY << "--homepage=") << QUrl(DEFAULT);
        QTest::newRow("homepage switch missing scheme") << (QStringList() << BINARY << "--homepage=example.com") << QUrl("http://example.com");
    }

    void shouldRecordURL()
    {
        QFETCH(QStringList, args);
        QFETCH(QUrl, url);
        QCOMPARE(CommandLineParser(args).url(), url);
    }

    void shouldHaveDesktopFileHint_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<QString>("hint");
        QString BINARY("webbrowser-app");

        QTest::newRow("no hint") << (QStringList() << BINARY) << "";
        QTest::newRow("full path hint") << (QStringList() << BINARY << "--desktop_file_hint=/usr/share/applications/webbrowser-app.desktop") << "webbrowser-app";
        QTest::newRow("only .desktop file") << (QStringList() << BINARY << "--desktop_file_hint=webbrowser-app.desktop") << "webbrowser-app";
        QTest::newRow("webapp") << (QStringList() << BINARY << "--desktop_file_hint=/usr/share/applications/amazon-webapp.desktop") << "amazon-webapp";
    }

    void shouldHaveDesktopFileHint()
    {
        QFETCH(QStringList, args);
        QFETCH(QString, hint);
        QCOMPARE(CommandLineParser(args).desktopFileHint(), hint);
    }

    void shouldRunRemoteInspector_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<bool>("inspector");
        QString BINARY("webbrowser-app");
        QString URL("http://ubuntu.com");
        QTest::newRow("no switch") << (QStringList() << BINARY) << false;
        QTest::newRow("switch only") << (QStringList() << BINARY << "--inspector") << true;
        QTest::newRow("switch before URL") << (QStringList() << BINARY << "--inspector" << URL) << true;
        QTest::newRow("switch after URL") << (QStringList() << BINARY << URL << "--inspector") << true;
        QTest::newRow("switch typo") << (QStringList() << BINARY << "--ispector") << false;
        QTest::newRow("switch uppercase") << (QStringList() << BINARY << "--INSPECTOR") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "-h" << "--inspector") << false;
        QTest::newRow("help precludes other switches") << (QStringList() << BINARY << "--help" << "--inspector") << false;
    }

    void shouldRunRemoteInspector()
    {
        QFETCH(QStringList, args);
        QFETCH(bool, inspector);
        QCOMPARE(CommandLineParser(args).remoteInspector(), inspector);
    }
};

QTEST_MAIN(CommandLineParserTests)
#include "tst_CommandLineParserTests.moc"
