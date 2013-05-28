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
#include <QtCore/QDir>
#include <QtCore/QMetaObject>
#include <QtCore/QStandardPaths>
#include <QtNetwork/QNetworkInterface>
#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>

// local
#include "config.h"
#include "commandline-parser.h"
#include "history-model.h"
#include "history-matches-model.h"
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
    , m_view(0)
    , m_arguments(0)
    , m_history(0)
    , m_historyMatches(0)
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

    m_view = new QQuickView;
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle(APP_TITLE);
    m_view->resize(800, 600);
    connect(m_view->engine(), SIGNAL(quit()), SLOT(quit()));

    QDir dataLocation(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!dataLocation.exists()) {
        QDir::root().mkpath(dataLocation.absolutePath());
    }
    m_history = new HistoryModel(dataLocation.filePath("history.sqlite"), this);
    m_view->rootContext()->setContextProperty("historyModel", m_history);
    m_historyMatches = new HistoryMatchesModel(m_history, this);
    m_view->rootContext()->setContextProperty("historyMatches", m_historyMatches);

    m_view->setSource(QUrl::fromLocalFile(UbuntuBrowserDirectory() + "/Browser.qml"));
    QQuickItem* browser = m_view->rootObject();
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
