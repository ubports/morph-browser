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
#include <QtCore/QDir>
#include <QtNetwork/QNetworkInterface>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickWindow>

// local
#include "config.h"
#include "commandline-parser.h"
#include "webbrowser-app.h"
#include "webbrowser-window.h"


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
    , m_webbrowserWindowProxy(0)
{
}

WebBrowserApp::~WebBrowserApp()
{
    delete m_component;
    delete m_engine;
    delete m_webbrowserWindowProxy;
}

bool WebBrowserApp::initialize()
{
    Q_ASSERT(m_window == 0);

    m_arguments = new CommandLineParser(arguments(), this);
    if (m_arguments->help()) {
        m_arguments->printUsage();
        return false;
    }

    // Handle legacy platforms (i.e. current desktop versions, where
    // applications are not started by the Ubuntu ApplicationManager).
    if (qgetenv("APP_ID").isEmpty()) {
        QString appId = m_arguments->appId().isEmpty() ? QString(APP_ID) : m_arguments->appId();
        qputenv("APP_ID", appId.toUtf8());
    }
    // Ensure that application-specific data is written where it ought to.
    QString appPkgName = qgetenv("APP_ID").split('_').first();
    QCoreApplication::setApplicationName(appPkgName);

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
    m_webbrowserWindowProxy = new WebBrowserWindow();
    context->setContextProperty("webbrowserWindowProxy", m_webbrowserWindowProxy);

    QObject* browser = m_component->create();
    m_window = qobject_cast<QQuickWindow*>(browser);
    m_webbrowserWindowProxy->setWindow(m_window);

    browser->setProperty("chromeless", m_arguments->chromeless());
    browser->setProperty("developerExtrasEnabled", m_arguments->remoteInspector());

    QString webappModelSearchPath = m_arguments->webappModelSearchPath();
    if (! webappModelSearchPath.isEmpty())
    {
        QDir webappModelSearchDir(webappModelSearchPath);

        // makeAbsolute is idempotent
        webappModelSearchDir.makeAbsolute();
        if (webappModelSearchDir.exists())
        {
            browser->setProperty("webappModelSearchPath", webappModelSearchDir.path());
        }
    }
    browser->setProperty("webapp", m_arguments->webapp());
    browser->setProperty("webappName", m_arguments->webappName());

    CommandLineParser::ChromeElementFlags chromeFlags = m_arguments->chromeFlags();
    if (chromeFlags != 0)
    {
        bool backForwardButtonsVisible = (chromeFlags & CommandLineParser::BACK_FORWARD_BUTTONS);
        bool addressBarVisible = (chromeFlags & CommandLineParser::ADDRESS_BAR);
        bool activityButtonVisible = (chromeFlags & CommandLineParser::ACTIVITY_BUTTON);

        browser->setProperty("backForwardButtonsVisible", backForwardButtonsVisible);
        browser->setProperty("addressBarVisible", addressBarVisible);
        browser->setProperty("activityButtonVisible", activityButtonVisible);
    }

    QStringList urlPatterns = m_arguments->webappUrlPatterns();
    if ( ! urlPatterns.isEmpty())
    {
        for (int i = 0; i < urlPatterns.count(); ++i)
        {
            urlPatterns[i].replace("*", "[^ ]*");
        }
        browser->setProperty("webappUrlPatterns", urlPatterns);
    }

    // Set the desired pixel ratio (not needed once we use Qt's way of calculating
    // the proper pixel ratio by device/screen)
    float webkitDpr = getQtWebkitDpr();
    browser->setProperty("qtwebkitdpr", webkitDpr);

    // When a webapp is being launched (by name), the url is pulled from its 'homepage'.
    QUrl url;
    if (m_arguments->webappName().isEmpty()) {
        url = m_arguments->url();
    }

    QMetaObject::invokeMethod(browser, "newTab",
                              Q_ARG(QVariant, url),
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
