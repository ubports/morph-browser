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

// Qt
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtQml>

static float getQtWebkitDpr()
{
    QByteArray stringValue = qgetenv("QTWEBKIT_DPR");
    bool ok = false;
    float value = stringValue.toFloat(&ok);
    return ok ? value : 1.0;
}

void UbuntuBrowserPlugin::initializeEngine(QQmlEngine* engine, const char* uri)
{
    Q_UNUSED(uri);

    QDir dataLocation(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!dataLocation.exists()) {
        QDir::root().mkpath(dataLocation.absolutePath());
    }
    QQmlContext* context = engine->rootContext();
    context->setContextProperty("dataLocation", dataLocation.absolutePath());

    // Set the desired pixel ratio (not needed once we use Qt’s way of
    // calculating the proper pixel ratio by device/screen).
    context->setContextProperty("QtWebKitDPR", getQtWebkitDpr());
}

void UbuntuBrowserPlugin::registerTypes(const char* uri)
{
    Q_ASSERT(uri == QLatin1String("Ubuntu.Components.Extras.Browser"));
}
