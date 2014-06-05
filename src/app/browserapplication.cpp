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
#include <QtCore/QLibrary>
#include <QtCore/QtGlobal>
#include <QtNetwork/QNetworkInterface>
#include <QtGui/QOpenGLContext>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickWindow>
#if QT_VERSION < QT_VERSION_CHECK(5, 3, 0)
#include <QtQuick/private/qsgcontext_p.h>
#else
#include <QtGui/private/qopenglcontext_p.h>
#endif

// local
#include "browserapplication.h"
#include "config.h"
#include "webbrowser-window.h"

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

QString BrowserApplication::appId() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--app-id=")) {
            return argument.split("--app-id=")[1];
        }
    }
    return QString();
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
    QString appPkgName = qgetenv("APP_ID").split('_').first();
    QCoreApplication::setApplicationName(appPkgName);

    // Enable compositing in oxide
    QOpenGLContext* glcontext = new QOpenGLContext(this);
    glcontext->create();
#if QT_VERSION < QT_VERSION_CHECK(5, 3, 0)
    QSGContext::setSharedOpenGLContext(glcontext);
#else
    QOpenGLContextPrivate::setGlobalShareContext(glcontext);
#endif

    bool inspector = m_arguments.contains("--inspector");
    if (inspector) {
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

    QObject* browser = m_component->beginCreate(context);
    m_window = qobject_cast<QQuickWindow*>(browser);
    m_webbrowserWindowProxy->setWindow(m_window);

    browser->setProperty("developerExtrasEnabled", inspector);

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
