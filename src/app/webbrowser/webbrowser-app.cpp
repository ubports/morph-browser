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
#include "bookmarks-folderlist-model.h"
#include "cache-deleter.h"
#include "config.h"
#include "file-operations.h"
#include "history-domainlist-chronological-model.h"
#include "history-domainlist-model.h"
#include "history-lastvisitdatelist-model.h"
#include "history-lastvisitdate-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"
#include "limit-proxy-model.h"
#include "searchengine.h"
#include "suggestions-filter-model.h"
#include "tabs-model.h"
#include "top-sites-model.h"
#include "webbrowser-app.h"

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

static QObject* CacheDeleter_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new CacheDeleter();
}

bool WebbrowserApp::initialize()
{
    const char* uri = "webbrowserapp.private";
    qmlRegisterType<HistoryModel>(uri, 0, 1, "HistoryModel");
    qmlRegisterType<HistoryTimeframeModel>(uri, 0, 1, "HistoryTimeframeModel");
    qmlRegisterType<TopSitesModel>(uri, 0 , 1, "TopSitesModel");
    qmlRegisterType<HistoryDomainListModel>(uri, 0, 1, "HistoryDomainListModel");
    qmlRegisterType<HistoryDomainListChronologicalModel>(uri, 0, 1, "HistoryDomainListChronologicalModel");
    qmlRegisterType<HistoryLastVisitDateListModel>(uri, 0, 1, "HistoryLastVisitDateListModel");
    qmlRegisterType<HistoryLastVisitDateModel>(uri, 0, 1, "HistoryLastVisitDateModel");
    qmlRegisterType<LimitProxyModel>(uri, 0 , 1, "LimitProxyModel");
    qmlRegisterType<TabsModel>(uri, 0, 1, "TabsModel");
    qmlRegisterType<BookmarksModel>(uri, 0, 1, "BookmarksModel");
    qmlRegisterType<BookmarksFolderListModel>(uri, 0, 1, "BookmarksFolderListModel");
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterType<SearchEngine>(uri, 0, 1, "SearchEngine");
    qmlRegisterSingletonType<CacheDeleter>(uri, 0, 1, "CacheDeleter", CacheDeleter_singleton_factory);
    qmlRegisterType<SuggestionsFilterModel>(uri, 0, 1, "SuggestionsFilterModel");

    if (BrowserApplication::initialize("webbrowser/webbrowser-app.qml")) {
        QStringList searchEnginesSearchPaths;
        searchEnginesSearchPaths << QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/searchengines";
        searchEnginesSearchPaths << UbuntuBrowserDirectory() + "/webbrowser/searchengines";
        m_engine->rootContext()->setContextProperty("searchEnginesSearchPaths", searchEnginesSearchPaths);

        m_window->setProperty("newSession", m_arguments.contains("--new-session"));

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
