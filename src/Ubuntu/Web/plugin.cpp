/*
 * Copyright 2013-2014 Canonical Ltd.
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
#include "favicon-image-provider.h"

// Qt
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtCore/QtGlobal>
#include <QtGui/QGuiApplication>
#include <QtQml>
#include <QtQml/QQmlInfo>

static float getQtWebkitDpr()
{
    QByteArray stringValue = qgetenv("QTWEBKIT_DPR");
    bool ok = false;
    float value = stringValue.toFloat(&ok);
    return ok ? value : 1.0;
}

static QString getFormFactor()
{
    // This implementation only considers two possible form factors: desktop,
    // and mobile (which includes phones and tablets).
    // XXX: do we need to consider other form factors, such as tablet?
    const char* DESKTOP = "desktop";
    const char* MOBILE = "mobile";

    // The "DESKTOP_MODE" environment variable can be used to force the form
    // factor to desktop, when set to any valid value other than 0.
    const char* DESKTOP_MODE_ENV_VAR = "DESKTOP_MODE";
    if (qEnvironmentVariableIsSet(DESKTOP_MODE_ENV_VAR)) {
        QByteArray stringValue = qgetenv(DESKTOP_MODE_ENV_VAR);
        bool ok = false;
        int value = stringValue.toInt(&ok);
        if (ok) {
            return (value == 0) ? MOBILE : DESKTOP;
        }
    }

    // XXX: Assume that QtUbuntu means mobile, which is currently the case,
    // but may not remain true forever.
    QString platform = QGuiApplication::platformName();
    if ((platform == "ubuntu") || (platform == "ubuntumirclient")) {
        return MOBILE;
    }

    return DESKTOP;
}

static int getDevtoolsPort()
{
    const int DEVTOOLS_INVALID_PORT = -1;

    int port = DEVTOOLS_INVALID_PORT;
    const char* DEVTOOLS_PORT_ENV_VAR = "UBUNTU_WEBVIEW_DEVTOOLS_PORT";

    if (qEnvironmentVariableIsSet(DEVTOOLS_PORT_ENV_VAR)) {
        QByteArray environmentVarValue = qgetenv(DEVTOOLS_PORT_ENV_VAR);
        bool ok = false;
        int value = environmentVarValue.toInt(&ok);
        if (ok) {
            port = value;
        }
    }
    return port > 0 ? port : DEVTOOLS_INVALID_PORT;
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

    if (uri == QLatin1String("Ubuntu.Components.Extras.Browser")) {
        // Set the desired pixel ratio (not needed once we use Qt’s way of
        // calculating the proper pixel ratio by device/screen).
        context->setContextProperty("QtWebKitDPR", getQtWebkitDpr());
    }

    context->setContextProperty("formFactor", getFormFactor());
    context->setContextProperty("webviewDevtoolsDebugPort", getDevtoolsPort());

    engine->addImageProvider("favicon", new FaviconImageProvider());
}

void UbuntuBrowserPlugin::registerTypes(const char* uri)
{
    Q_ASSERT(uri == QLatin1String("Ubuntu.Components.Extras.Browser")
          || uri == QLatin1String("Ubuntu.Web"));

    if (uri == QLatin1String("Ubuntu.Components.Extras.Browser")) {
        qmlInfo(0) << "WARNING: the use of the Ubuntu.Components.Extras.Browser "
                      "namespace is deprecated, please consider updating your "
                      "applications to import Ubuntu.Web instead.";
    }
}
