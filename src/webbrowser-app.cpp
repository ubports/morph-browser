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
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlEngine>

// local
#include "config.h"
#include "commandline-parser.h"
#include "webbrowser-app.h"

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

static float getQtWebkitDpr()
{
    const char* envVar = "QTWEBKIT_DPR";
    QByteArray stringValue = qgetenv(envVar);
    bool ok;
    float value = stringValue.toFloat(&ok);
    float defaultValue = 1.0;
    return ok ? value : defaultValue;
}

WebBrowserApp::WebBrowserApp(int& argc, char** argv)
    : QApplication(argc, argv)
    , m_view(0)
    , m_arguments(0)
{
}

WebBrowserApp::~WebBrowserApp()
{
    delete m_view;
}

bool WebBrowserApp::initialize()
{
    Q_ASSERT(m_view == 0);

    m_arguments = new CommandLineParser(arguments(), this);
    if (m_arguments->help()) {
        m_arguments->printUsage();
        return false;
    }

    m_view = new QQuickView;
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle(APP_TITLE);
    // phone form factor
    float gridUnit = getGridUnit();
    m_view->resize(40 * gridUnit, 68 * gridUnit);
    connect(m_view->engine(), SIGNAL(quit()), SLOT(quit()));

    m_view->setSource(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/Browser.qml"));
    QQuickItem* browser = m_view->rootObject();
    browser->setProperty("chromeless", m_arguments->chromeless());
    browser->setProperty("url", m_arguments->url());
    if (m_arguments->desktopFileHint().isEmpty()) {
        // see comments about this property in Browser.qml inside the HUD Component
        browser->setProperty("desktopFileHint", "<not set>");
    } else {
        browser->setProperty("desktopFileHint", m_arguments->desktopFileHint());
    }

    // Set the desired pixel ratio (not needed once we use Qt's way of calculating
    // the proper pixel ratio by device/screen)
    float webkitDpr = getQtWebkitDpr();
    browser->setProperty("qtwebkitdpr", webkitDpr);

    connect(browser, SIGNAL(titleChanged()), SLOT(onTitleChanged()));

    return true;
}

int WebBrowserApp::run()
{
    Q_ASSERT(m_view != 0);

    if (m_arguments->fullscreen()) {
        m_view->showFullScreen();
    } else {
        m_view->show();
    }
    return exec();
}

void WebBrowserApp::onTitleChanged()
{
    QQuickItem* browser = m_view->rootObject();
    QString title = browser->property("title").toString();
    if (title.isEmpty()) {
        m_view->setTitle(APP_TITLE);
    } else {
        m_view->setTitle(QString("%1 - %2").arg(title, APP_TITLE));
    }
}
