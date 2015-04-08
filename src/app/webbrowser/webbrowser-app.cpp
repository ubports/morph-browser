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

#include "bookmarks-model.h"
#include "config.h"
#include "file-operations.h"
#include "history-model.h"
#include "history-matches-model.h"
#include "history-timeframe-model.h"
#include "history-byvisits-model.h"
#include "history-hidden-model.h"
#include "history-domainlist-model.h"
#include "history-domainlist-chronological-model.h"
#include "limit-proxy-model.h"
#include "searchengine.h"
#include "settings.h"
#include "tabs-model.h"
#include "webbrowser-app.h"

// system
#include <string.h>
#include <unistd.h>

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QString>
#include <QtCore/QTextStream>
#include <QtCore/QtGlobal>
#include <QtCore/QVariant>
#include <QtQml/QtQml>
#include <QtQuick/QQuickWindow>

WebbrowserApp::WebbrowserApp(int& argc, char** argv)
    : BrowserApplication(argc, argv)
{
}

static QObject* FileOperations_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new FileOperations();
}

bool WebbrowserApp::initialize()
{
    // Re-direct webapps to the dedicated container for backward compatibility
    // with 13.10
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webapp")) {
            qWarning() << "Deprecated webapp options: use the webapp-container program instead";

            int size = m_arguments.size();
            char* argv[size + 2];
            argv[0] = (char*) "webapp-container";
            for (int i = 0; i < size; ++i) {
                QByteArray bytes = m_arguments.at(i).toLocal8Bit();
                argv[i + 1] = new char[bytes.size() + 1];
                strcpy(argv[i + 1], bytes.constData());
            }
            argv[size + 1] = NULL;

            QCoreApplication::exit(execvp(argv[0], argv));
            return false;
        }
    }

    const char* uri = "webbrowserapp.private";
    qmlRegisterType<HistoryModel>(uri, 0, 1, "HistoryModel");
    qmlRegisterType<HistoryMatchesModel>(uri, 0, 1, "HistoryMatchesModel");
    qmlRegisterType<HistoryTimeframeModel>(uri, 0, 1, "HistoryTimeframeModel");
    qmlRegisterType<HistoryByVisitsModel>(uri, 0 , 1, "HistoryByVisitsModel");
    qmlRegisterType<HistoryHiddenModel>(uri, 0 , 1, "HistoryHiddenModel");
    qmlRegisterType<HistoryDomainListModel>(uri, 0, 1, "HistoryDomainListModel");
    qmlRegisterType<HistoryDomainListChronologicalModel>(uri, 0, 1, "HistoryDomainListChronologicalModel");
    qmlRegisterType<LimitProxyModel>(uri, 0 , 1, "LimitProxyModel");
    qmlRegisterType<TabsModel>(uri, 0, 1, "TabsModel");
    qmlRegisterType<BookmarksModel>(uri, 0, 1, "BookmarksModel");
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterType<SearchEngine>(uri, 0, 1, "SearchEngine");

    if (BrowserApplication::initialize("webbrowser/webbrowser-app.qml")) {
        Settings settings;
        m_window->setProperty("homepage", settings.homepage());
        m_window->setProperty("searchEngine", settings.searchEngine());
        m_window->setProperty("allowOpenInBackgroundTab", settings.allowOpenInBackgroundTab());
        m_window->setProperty("restoreSession", settings.restoreSession() &&
                                                !m_arguments.contains("--new-session"));
        QVariantList urls;
        Q_FOREACH(const QUrl& url, this->urls()) {
            urls.append(url);
        }
        m_window->setProperty("urls", urls);
        m_component->completeCreate();
        return true;
    } else {
        return false;
    }
}

void WebbrowserApp::printUsage() const
{
    QTextStream out(stdout);
    QString command = QFileInfo(QCoreApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--fullscreen] [--maximized] [--inspector]"
                                << " [--app-id=APP_ID] [--new-session] [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help         display this help message and exit" << endl;
    out << "  --fullscreen       display full screen" << endl;
    out << "  --maximized        opens the application maximized" << endl;
    out << "  --inspector[=PORT] run a remote inspector on a specified port or " << REMOTE_INSPECTOR_PORT << " as the default port" << endl;
    out << "  --app-id=APP_ID    run the application with a specific APP_ID" << endl;
    out << "  --new-session      do not restore open tabs from the last session" << endl;
}

int main(int argc, char** argv)
{
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    WebbrowserApp app(argc, argv);
    if (app.initialize()) {
        return app.run();
    } else {
        return 0;
    }
}
