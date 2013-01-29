/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Qt
#include <QtCore/QFileInfo>
#include <QtCore/QTextStream>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>

// stdlib
#include <cstdio>

// local
#include "config.h"
#include "ubuntu-browser.h"

static float getGridUnit()
{
    // Inspired by the UI toolkit’s code
    // (modules/Ubuntu/Components/plugin/ucunits.cpp)
    // as it is not publicly exposed.
    const char* envVar = "GRID_UNIT_PX";
    QByteArray stringValue = qgetenv(envVar);
    bool ok;
    float value = stringValue.toFloat(&ok);
    float defaultValue = 8;
    return ok ? value : defaultValue;
}

static void printUsage()
{
    QTextStream out(stdout);
    QString command = QFileInfo(QApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--chromeless] [--fullscreen] [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help     display this help message and exit" << endl;
    out << "  --chromeless   do not display any chrome (web application mode)" << endl;
    out << "  --fullscreen   display full screen" << endl;
}

UbuntuBrowser::UbuntuBrowser(int& argc, char** argv)
    : QApplication(argc, argv)
    , m_view(0)
    , m_fullscreen(false)
{
}

UbuntuBrowser::~UbuntuBrowser()
{
    delete m_view;
}

bool UbuntuBrowser::initialize()
{
    Q_ASSERT(m_view == 0);

    QStringList arguments = this->arguments();
    arguments.removeFirst();
    if (arguments.contains("--help") || arguments.contains("-h")) {
        printUsage();
        return false;
    }

    m_view = new QQuickView;
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle(APP_TITLE);
    // phone form factor
    float gridUnit = getGridUnit();
    m_view->resize(40 * gridUnit, 68 * gridUnit);

    bool chromeless = arguments.contains("--chromeless");
    m_fullscreen = arguments.contains("--fullscreen");
    QUrl url(DEFAULT_HOMEPAGE);
    Q_FOREACH(QString argument, arguments) {
        if (!argument.startsWith("--")) {
            url = argument;
            break;
        }
    }

    m_view->setSource(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/Browser.qml"));
    QQuickItem* browser = m_view->rootObject();
    browser->setProperty("chromeless", chromeless);
    browser->setProperty("url", url);
    connect(browser, SIGNAL(titleChanged()), SLOT(onTitleChanged()));

    return true;
}

int UbuntuBrowser::run()
{
    Q_ASSERT(m_view != 0);

    if (m_fullscreen) {
        m_view->showFullScreen();
    } else {
        m_view->show();
    }
    return exec();
}

void UbuntuBrowser::onTitleChanged()
{
    QQuickItem* browser = m_view->rootObject();
    QString title = browser->property("title").toString();
    if (title.isEmpty()) {
        m_view->setTitle(APP_TITLE);
    } else {
        m_view->setTitle(QString("%1 - %2").arg(title, APP_TITLE));
    }
}
