/*
 * Copyright 2013-2016 Canonical Ltd.
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
#include "downloads-model.h"
#include "file-operations.h"
#include "history-domainlist-model.h"
#include "history-lastvisitdatelist-model.h"
#include "history-model.h"
#include "limit-proxy-model.h"
#include "searchengine.h"
#include "text-search-filter-model.h"
#include "tabs-model.h"
#include "webbrowser-app.h"

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QString>
#include <QtCore/QTextStream>
#include <QtCore/QtGlobal>
#include <QtCore/QVariant>
#include <QtQml/QQmlProperty>
#include <QtQml/QtQml>
#include <QtQuick/QQuickWindow>

WebbrowserApp::WebbrowserApp(int& argc, char** argv)
    : BrowserApplication(argc, argv)
{
}

#define MAKE_SINGLETON_FACTORY(type) \
    static QObject* type##_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine) { \
        Q_UNUSED(engine); \
        Q_UNUSED(scriptEngine); \
        return new type(); \
    }

MAKE_SINGLETON_FACTORY(FileOperations)
MAKE_SINGLETON_FACTORY(CacheDeleter)
MAKE_SINGLETON_FACTORY(BookmarksModel)
MAKE_SINGLETON_FACTORY(HistoryModel)
MAKE_SINGLETON_FACTORY(DownloadsModel)

bool WebbrowserApp::initialize()
{
    const char* uri = "webbrowserapp.private";
    qmlRegisterSingletonType<HistoryModel>(uri, 0, 1, "HistoryModel", HistoryModel_singleton_factory);
    qmlRegisterType<HistoryDomainListModel>(uri, 0, 1, "HistoryDomainListModel");
    qmlRegisterType<HistoryLastVisitDateListModel>(uri, 0, 1, "HistoryLastVisitDateListModel");
    qmlRegisterType<LimitProxyModel>(uri, 0 , 1, "LimitProxyModel");
    qmlRegisterType<TabsModel>(uri, 0, 1, "TabsModel");
    qmlRegisterSingletonType<BookmarksModel>(uri, 0, 1, "BookmarksModel", BookmarksModel_singleton_factory);
    qmlRegisterType<BookmarksFolderListModel>(uri, 0, 1, "BookmarksFolderListModel");
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterType<SearchEngine>(uri, 0, 1, "SearchEngine");
    qmlRegisterSingletonType<CacheDeleter>(uri, 0, 1, "CacheDeleter", CacheDeleter_singleton_factory);
    qmlRegisterSingletonType<DownloadsModel>(uri, 0, 1, "DownloadsModel", DownloadsModel_singleton_factory);
    qmlRegisterType<TextSearchFilterModel>(uri, 0, 1, "TextSearchFilterModel");

    if (BrowserApplication::initialize("webbrowser/webbrowser-app.qml")) {
        QStringList searchEnginesSearchPaths;
        searchEnginesSearchPaths << QStandardPaths::writableLocation(QStandardPaths::DataLocation) + "/searchengines";
        searchEnginesSearchPaths << UbuntuBrowserDirectory() + "/webbrowser/searchengines";
        m_engine->rootContext()->setContextProperty("searchEnginesSearchPaths", searchEnginesSearchPaths);

        m_engine->rootContext()->setContextProperty("__platformName", platformName());

        QQmlProperty::write(m_object, QStringLiteral("newSession"), m_arguments.contains("--new-session"));

        QVariantList urls;
        Q_FOREACH(const QUrl& url, this->urls()) {
            urls.append(url);
        }
        QQmlProperty::write(m_object, QStringLiteral("urls"), urls);

        m_component->completeCreate();

        QMetaObject::invokeMethod(m_object, "init");

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
