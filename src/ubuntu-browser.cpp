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
#include <QtCore/QtGlobal>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>

// local
#include "config.h"
#include "commandline-parser.h"
#include "ubuntu-browser.h"

static void fixPath()
{
    QByteArray path = qgetenv("PATH");
    path.prepend("/opt/qt5/bin:");
    qputenv("PATH", path);
}

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

UbuntuBrowser::UbuntuBrowser(int& argc, char** argv)
    : QApplication(argc, argv)
    , m_view(0)
    , m_arguments(0)
{
}

UbuntuBrowser::~UbuntuBrowser()
{
    delete m_view;
}

bool UbuntuBrowser::initialize()
{
    Q_ASSERT(m_view == 0);

    // XXX: fix the PATH until Qt5 is properly installed on the system
    fixPath();

    m_arguments = new CommandLineParser(arguments(), this);
    if (m_arguments->help()) {
        m_arguments->printUsage();
        return false;
    }

    m_view = new QQuickView;
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setWindowTitle(APP_TITLE);
    // phone form factor
    float gridUnit = getGridUnit();
    m_view->resize(40 * gridUnit, 68 * gridUnit);

    m_view->setSource(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/Browser.qml"));
    QQuickItem* browser = m_view->rootObject();
    browser->setProperty("chromeless", m_arguments->chromeless());
    browser->setProperty("url", m_arguments->url());
    connect(browser, SIGNAL(titleChanged()), SLOT(onTitleChanged()));

    return true;
}

int UbuntuBrowser::run()
{
    Q_ASSERT(m_view != 0);

    if (m_arguments->fullscreen()) {
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
        m_view->setWindowTitle(APP_TITLE);
    } else {
        m_view->setWindowTitle(QString("%1 - %2").arg(title, APP_TITLE));
    }
}
