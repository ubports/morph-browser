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
#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QObject>
#include <QtCore/QStandardPaths>
#include <QtCore/QtGlobal>
#include <QtGui/QGuiApplication>
#include <QtQml>
#include <QtQml/QQmlInfo>

class UbuntuWebPluginContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString dataLocation READ dataLocation NOTIFY dataLocationChanged)
    Q_PROPERTY(QString formFactor READ formFactor CONSTANT)
    Q_PROPERTY(QString webviewDevtoolsDebugHost READ devtoolsHost CONSTANT)
    Q_PROPERTY(int webviewDevtoolsDebugPort READ devtoolsPort CONSTANT)

public:
    UbuntuWebPluginContext(QObject* parent = 0);

    QString dataLocation() const;
    QString formFactor();
    QString devtoolsHost();
    int devtoolsPort();

Q_SIGNALS:
    void dataLocationChanged() const;

private:
    QString m_formFactor;
    QString m_devtoolsHost;
    int m_devtoolsPort;
};

UbuntuWebPluginContext::UbuntuWebPluginContext(QObject* parent)
    : QObject(parent)
    , m_devtoolsPort(-2)
{
    connect(QCoreApplication::instance(), SIGNAL(applicationNameChanged()),
            this, SIGNAL(dataLocationChanged()));
}

QString UbuntuWebPluginContext::dataLocation() const
{
    QDir location(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!location.exists()) {
        QDir::root().mkpath(location.absolutePath());
    }
    return location.absolutePath();
}

QString UbuntuWebPluginContext::formFactor()
{
    if (m_formFactor.isEmpty()) {
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
                m_formFactor = (value == 0) ? MOBILE : DESKTOP;
                return m_formFactor;
            }
        }

        // XXX: Assume that QtUbuntu means mobile, which is currently the case,
        // but may not remain true forever.
        QString platform = QGuiApplication::platformName();
        if ((platform == "ubuntu") || (platform == "ubuntumirclient")) {
            m_formFactor = MOBILE;
        } else {
            m_formFactor = DESKTOP;
        }
    }
    return m_formFactor;
}

QString UbuntuWebPluginContext::devtoolsHost()
{
    if (m_devtoolsHost.isNull()) {
        const char* DEVTOOLS_HOST_ENV_VAR = "UBUNTU_WEBVIEW_DEVTOOLS_HOST";
        if (qEnvironmentVariableIsSet(DEVTOOLS_HOST_ENV_VAR)) {
            m_devtoolsHost = qgetenv(DEVTOOLS_HOST_ENV_VAR);
        } else {
            m_devtoolsHost = "";
        }
    }
    return m_devtoolsHost;
}

int UbuntuWebPluginContext::devtoolsPort()
{
    if (m_devtoolsPort == -2) {
        const int DEVTOOLS_INVALID_PORT = -1;
        m_devtoolsPort = DEVTOOLS_INVALID_PORT;

        const char* DEVTOOLS_PORT_ENV_VAR = "UBUNTU_WEBVIEW_DEVTOOLS_PORT";
        if (qEnvironmentVariableIsSet(DEVTOOLS_PORT_ENV_VAR)) {
            QByteArray environmentVarValue = qgetenv(DEVTOOLS_PORT_ENV_VAR);
            bool ok = false;
            int value = environmentVarValue.toInt(&ok);
            if (ok) {
                m_devtoolsPort = value;
            }
        }
        if (m_devtoolsPort <= 0) {
            m_devtoolsPort = DEVTOOLS_INVALID_PORT;
        }
    }
    return m_devtoolsPort;
}

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

    QQmlContext* context = engine->rootContext();
    context->setContextObject(new UbuntuWebPluginContext(context));

    if (uri == QLatin1String("Ubuntu.Components.Extras.Browser")) {
        // Set the desired pixel ratio (not needed once we use Qt’s way of
        // calculating the proper pixel ratio by device/screen).
        context->setContextProperty("QtWebKitDPR", getQtWebkitDpr());
    }

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

#include "plugin.moc"
