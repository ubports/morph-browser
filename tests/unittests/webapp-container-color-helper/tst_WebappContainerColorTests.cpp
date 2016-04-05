/*
 * Copyright 2016 Canonical Ltd.
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
#include <QtCore/QString>
#include <QtTest/QtTest>

// local
#include "webapp-container-helper.h"

class ContainerColorTests : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void cssColorToRgbTest_data()
    {
        QTest::addColumn<QString>("csscolor");
        QTest::addColumn<QString>("rgb");

        QTest::newRow("Empty CSS color") << "  " << "";
        QTest::newRow("Invalid CSS color") << " invalid " << "";
        QTest::newRow("Invalid RGB CSS color") << " rgb  (1,1," << "";
        QTest::newRow("Invalid RGB CSS color 2") << " rgb  (1,1 0)" << "";
        QTest::newRow("Invalid RGB CSS color 3") << " rgb  (1, e, 0)" << "";
        QTest::newRow("Valid SVG name CSS color") << " red " << "255,0,0";
        QTest::newRow("Valid RGB CSS color") << " rgb (255, 0, 0) " << "255,0,0";
        QTest::newRow("Valid plain RGB CSS color") << " #FF0000 " << "255,0,0";
        QTest::newRow("Valid short plain RGB CSS color") << " #36699 " << "3,102,153";
        QTest::newRow("Valid shortest plain RGB CSS color") << " #366 " << "51,102,102";
        QTest::newRow("Valid very short plain RGB CSS color") << " #000 " << "0,0,0";
        QTest::newRow("Valid SVG name CSS color") << " #FF000044 " << "0,0,68";
    }

    void cssColorToRgbTest()
    {
        QFETCH(QString, csscolor);
        QFETCH(QString, rgb);

        WebappContainerHelper helper;
        QCOMPARE(helper.rgbColorFromCSSColor(csscolor), rgb);
    }
};

QTEST_MAIN(ContainerColorTests)
#include "tst_WebappContainerColorTests.moc"
