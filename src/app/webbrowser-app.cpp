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
#include <QtCore/QMetaObject>
#include <QtNetwork/QNetworkInterface>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickWindow>

// local
#include "config.h"
#include "commandline-parser.h"
#include "webbrowser-app.h"

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
    , m_arguments(0)
    , m_engine(0)
    , m_component(0)
    , m_window(0)
{
}

WebBrowserApp::~WebBrowserApp()
{
    delete m_component;
    delete m_engine;
}

bool WebBrowserApp::initialize()
{
    Q_ASSERT(m_window == 0);

    m_arguments = new CommandLineParser(arguments(), this);
    if (m_arguments->help()) {
        m_arguments->printUsage();
        return false;
    }

    if (m_arguments->remoteInspector()) {
        QString host;
        Q_FOREACH(QHostAddress address, QNetworkInterface::allAddresses()) {
            if (!address.isLoopback() && (address.protocol() == QAbstractSocket::IPv4Protocol)) {
                host = address.toString();
                break;
            }
        }
        QString server;
        if (host.isEmpty()) {
            server = QString::number(REMOTE_INSPECTOR_PORT);
        } else {
            server = QString("%1:%2").arg(host, QString::number(REMOTE_INSPECTOR_PORT));
        }
        qputenv("QTWEBKIT_INSPECTOR_SERVER", server.toUtf8());
    }

    m_engine = new QQmlEngine;
    connect(m_engine, SIGNAL(quit()), SLOT(quit()));
    if (!isRunningInstalled()) {
        m_engine->addImportPath(UbuntuBrowserImportsDirectory());
    }
    QQmlContext* context = m_engine->rootContext();
    m_component = new QQmlComponent(m_engine);
    m_component->loadUrl(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/webbrowser-app.qml"));
    if (!m_component->isReady()) {
        qWarning() << m_component->errorString();
        return false;
    }

    QObject* browser = m_component->create();
    m_window = qobject_cast<QQuickWindow*>(browser);
    browser->setProperty("chromeless", m_arguments->chromeless());
    browser->setProperty("developerExtrasEnabled", m_arguments->remoteInspector());
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

    QMetaObject::invokeMethod(browser, "newTab",
                              Q_ARG(QVariant, m_arguments->url()),
                              Q_ARG(QVariant, true));

    return true;
}

int WebBrowserApp::run()
{
    Q_ASSERT(m_window != 0);

    if (m_arguments->fullscreen()) {
        m_window->showFullScreen();
    } else {
        m_window->show();
    }
    return exec();
}
