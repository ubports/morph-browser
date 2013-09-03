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
    void shouldPrintUsage()
    {
        CommandLineParser(QStringList() << "webbrowser-app").printUsage();
    }

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

    void shouldUseAppId_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<QString>("appId");
        QString BINARY("webbrowser-app");
        QString APP_ID("webbrowser-app");
        QTest::newRow("no switch") << (QStringList() << BINARY) << QString();
        QTest::newRow("empty switch") << (QStringList() << BINARY << "--app-id=") << QString();
        QTest::newRow("no value switch") << (QStringList() << BINARY << "--app-id") << QString();
        QTest::newRow("valid appid switch") << (QStringList() << BINARY << (QString("--app-id=") + APP_ID)) << APP_ID;
    }

    void shouldUseAppId()
    {
        QFETCH(QStringList, args);
        QFETCH(QString, appId);
        QCOMPARE(CommandLineParser(args).appId(), appId);
    }

    void shouldRunAsWebApp_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<bool>("webapp");
        QTest::addColumn<QString>("webappName");

        QString BINARY("webbrowser-app");
        QString WEBAPPNAME("My Web App: Hi All!");
        QString ESCAPED_WEBAPPNAME(WEBAPPNAME.toUtf8().toBase64());

        QTest::newRow("no switch") << (QStringList() << BINARY) << false << QString();
        QTest::newRow("switch only") << (QStringList() << BINARY << "--webapp") << true << QString();
        QTest::newRow("switch and webapp name") << (QStringList() << BINARY << "--webapp=" + ESCAPED_WEBAPPNAME) << true << WEBAPPNAME;
        QTest::newRow("switch and escaped webapp name with typo") << (QStringList() << BINARY << "--webdapp=" + ESCAPED_WEBAPPNAME) << false << QString();
        QTest::newRow("switch uppercase") << (QStringList() << BINARY << "--WEBAPP") << false << QString();
    }

    void shouldRunAsWebApp()
    {
        QFETCH(QStringList, args);
        QFETCH(bool, webapp);
        QFETCH(QString, webappName);
        QCOMPARE(CommandLineParser(args).webapp(), webapp);
        QCOMPARE(CommandLineParser(args).webappName(), webappName);
    }

    void shouldUseChrome_data()
    {
        QTest::addColumn<QStringList>("args");
        QTest::addColumn<int>("chrome");

        QString BINARY("webbrowser-app");

        QString CHROME_BACK_FORWARD("back-forward");
        QString CHROME_RELOAD("reload");
        QString CHROME_ADDRESS_BAR("addressbar");

        QTest::newRow("no switch") << (QStringList() << BINARY)
                                   << static_cast<int>(CommandLineParser::NO_CHROME_FLAGS);

        QTest::newRow("switch only") << (QStringList() << BINARY << "--chrome")
                                     << static_cast<int>(CommandLineParser::NO_CHROME_FLAGS);
        QTest::newRow("empty switch") << (QStringList() << BINARY << "--chrome=")
                                      << static_cast<int>(CommandLineParser::NO_CHROME_FLAGS);

        QTest::newRow("switch with one chrome")
                << (QStringList() << BINARY << (QString("--chrome=") + CHROME_BACK_FORWARD))
                << static_cast<int>(CommandLineParser::BACK_FORWARD_BUTTONS);

        QTest::newRow("switch and multiple trimmed chromes")
                << (QStringList() << BINARY << (QString("--chrome=") + CHROME_BACK_FORWARD + " ; " + CHROME_RELOAD + " ;  ; " + CHROME_ADDRESS_BAR))
                << static_cast<int>(CommandLineParser::BACK_FORWARD_BUTTONS
                                    | CommandLineParser::ACTIVITY_BUTTON
                                    | CommandLineParser::ADDRESS_BAR);
    }

    void shouldUseChrome()
    {
        QFETCH(QStringList, args);
        QFETCH(int, chrome);
        QVERIFY(CommandLineParser(args).chrome() == chrome);
    }
};

QTEST_MAIN(CommandLineParserTests)
#include "tst_CommandLineParserTests.moc"
