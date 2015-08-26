/*
 * Copyright 2013-2015 Canonical Ltd.
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
#include <QtCore/QLibrary>
#include <QtCore/QtGlobal>
#include <QtNetwork/QNetworkInterface>
#include <QtGui/QOpenGLContext>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQml/QtQml>
#include <QtQuick/QQuickWindow>

// local
#include "browserapplication.h"
#include "config.h"
#include "favicon-fetcher.h"
#include "mime-database.h"
#include "session-storage.h"
#include "webbrowser-window.h"

#include "TouchRegistry.h"
#include "Ubuntu/Gestures/Direction.h"
#include "Ubuntu/Gestures/DirectionalDragArea.h"

BrowserApplication::BrowserApplication(int& argc, char** argv)
    : QApplication(argc, argv)
    , m_engine(0)
    , m_window(0)
    , m_component(0)
    , m_webbrowserWindowProxy(0)
{
    m_arguments = arguments();
    m_arguments.removeFirst();
}

BrowserApplication::~BrowserApplication()
{
    if (m_webbrowserWindowProxy) {
        m_webbrowserWindowProxy->setWindow(NULL);
    }
    delete m_window;
    delete m_webbrowserWindowProxy;
    delete m_component;
    delete m_engine;
}

QString BrowserApplication::inspectorPort() const
{
    QString port;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument == "--inspector") {
            // default port
            port = QString::number(REMOTE_INSPECTOR_PORT);
            break;
        }
        if (argument.startsWith("--inspector=")) {
            port = argument.split("--inspector=")[1];
            break;
        }
    }
    return port;
}

QString BrowserApplication::inspectorHost() const
{
    QString host;
    Q_FOREACH(QHostAddress address, QNetworkInterface::allAddresses()) {
        if (!address.isLoopback() && (address.protocol() == QAbstractSocket::IPv4Protocol)) {
            host = address.toString();
            break;
        }
    }
    return host;
}

QString BrowserApplication::appId() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--app-id=")) {
            return argument.split("--app-id=")[1];
        }
    }
    return QString();
}

static QObject* MimeDatabase_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new MimeDatabase();
}

static QObject* Direction_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new Direction();
}

bool BrowserApplication::initialize(const QString& qmlFileSubPath)
{
    Q_ASSERT(m_window == 0);

    if (m_arguments.contains("--help") || m_arguments.contains("-h")) {
        printUsage();
        return false;
    }

    // Handle legacy platforms (i.e. current desktop versions, where
    // applications are not started by the Ubuntu ApplicationManager).
    if (qgetenv("APP_ID").isEmpty()) {
        QString id = appId();
        if (id.isEmpty()) {
            id = QString(APP_ID);
        }
        qputenv("APP_ID", id.toUtf8());
    }
    // Ensure that application-specific data is written where it ought to.
    QStringList appIdParts =
        QString::fromUtf8(qgetenv("APP_ID")).split('_');
    QCoreApplication::setApplicationName(appIdParts.first());
    QCoreApplication::setOrganizationDomain(QCoreApplication::applicationName());
    // Get also the the first two components of the app ID: <package>_<app>,
    // which is needed by Online Accounts.
    QString unversionedAppId = QStringList(appIdParts.mid(0, 2)).join('_');

    QString devtoolsPort = inspectorPort();
    QString devtoolsHost = inspectorHost();
    bool inspectorEnabled = !devtoolsPort.isEmpty();
    if (inspectorEnabled) {
        qputenv("UBUNTU_WEBVIEW_DEVTOOLS_HOST", devtoolsHost.toUtf8());
        qputenv("UBUNTU_WEBVIEW_DEVTOOLS_PORT", devtoolsPort.toUtf8());
    }

    const char* uri = "webbrowsercommon.private";
    qmlRegisterType<FaviconFetcher>(uri, 0, 1, "FaviconFetcher");
    qmlRegisterSingletonType<MimeDatabase>(uri, 0, 1, "MimeDatabase", MimeDatabase_singleton_factory);
    qmlRegisterType<SessionStorage>(uri, 0, 1, "SessionStorage");

    const char* gesturesUri = "Ubuntu.Gestures";
    qmlRegisterSingletonType<Direction>(gesturesUri, 0, 1, "Direction", Direction_singleton_factory);
    qmlRegisterType<DirectionalDragArea>(gesturesUri, 0, 1, "DirectionalDragArea");

    m_engine = new QQmlEngine;
    connect(m_engine, SIGNAL(quit()), SLOT(quit()));
    if (!isRunningInstalled()) {
        m_engine->addImportPath(UbuntuBrowserImportsDirectory());
    }

    qmlEngineCreated(m_engine);

    QQmlContext* context = m_engine->rootContext();
    m_component = new QQmlComponent(m_engine);
    m_component->loadUrl(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/" + qmlFileSubPath));
    if (!m_component->isReady()) {
        qWarning() << m_component->errorString();
        return false;
    }
    m_webbrowserWindowProxy = new WebBrowserWindow();
    context->setContextProperty("webbrowserWindowProxy", m_webbrowserWindowProxy);
    context->setContextProperty("unversionedAppId", unversionedAppId);

    QObject* browser = m_component->beginCreate(context);
    m_window = qobject_cast<QQuickWindow*>(browser);
    m_webbrowserWindowProxy->setWindow(m_window);

    m_window->installEventFilter(new TouchRegistry(this));

    browser->setProperty("developerExtrasEnabled", inspectorEnabled);
    browser->setProperty("forceFullscreen", m_arguments.contains("--fullscreen"));

    return true;
}

void BrowserApplication::qmlEngineCreated(QQmlEngine*)
{}

int BrowserApplication::run()
{
    Q_ASSERT(m_window != 0);

    if (m_arguments.contains("--fullscreen")) {
        m_window->showFullScreen();
    } else if (m_arguments.contains("--maximized")) {
        m_window->showMaximized();
    } else {
        m_window->show();
    }
    return exec();
}

QList<QUrl> BrowserApplication::urls() const
{
    QList<QUrl> urls;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (!argument.startsWith("-")) {
            QUrl url = QUrl::fromUserInput(argument);
            if (url.isValid()) {
                urls.append(url);
            }
        }
    }
    return urls;
}
