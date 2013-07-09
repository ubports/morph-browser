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

#include "plugin.h"
#include "history-model.h"
#include "history-matches-model.h"
#include "tabs-model.h"
#include "webthumbnail-provider.h"
#include "webview-thumbnailer.h"


// Qt
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtQml>

void UbuntuBrowserPlugin::initializeEngine(QQmlEngine* engine, const char* uri)
{
    Q_UNUSED(uri);
    QDir dataLocation(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!dataLocation.exists()) {
        QDir::root().mkpath(dataLocation.absolutePath());
    }
    QQmlContext* context = engine->rootContext();
    context->setContextProperty("dataLocation", dataLocation.absolutePath());

    engine->addImageProvider(QLatin1String("webthumbnail"), new WebThumbnailProvider);
}

void UbuntuBrowserPlugin::registerTypes(const char* uri)
{
    Q_ASSERT(uri == QLatin1String("Ubuntu.Components.Extras.Browser"));
    qmlRegisterType<HistoryModel>(uri, 0, 1, "HistoryModel");
    qmlRegisterType<HistoryMatchesModel>(uri, 0, 1, "HistoryMatchesModel");
    qmlRegisterType<TabsModel>(uri, 0, 1, "TabsModel");
    qmlRegisterType<WebviewThumbnailer>(uri, 0, 1, "WebviewThumbnailer");
}
