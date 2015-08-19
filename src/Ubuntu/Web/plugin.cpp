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

#include "plugin.h"

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QObject>
#include <QtCore/QStandardPaths>
#include <QtCore/QStorageInfo>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QtGlobal>
#include <QtGui/QGuiApplication>
#include <QtQml>
#include <QtQml/QQmlInfo>

class UbuntuWebPluginContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString cacheLocation READ cacheLocation NOTIFY cacheLocationChanged)
    Q_PROPERTY(QString dataLocation READ dataLocation NOTIFY dataLocationChanged)
    Q_PROPERTY(QString formFactor READ formFactor CONSTANT)
    Q_PROPERTY(int cacheSizeHint READ cacheSizeHint NOTIFY cacheSizeHintChanged)
    Q_PROPERTY(QString webviewDevtoolsDebugHost READ devtoolsHost CONSTANT)
    Q_PROPERTY(int webviewDevtoolsDebugPort READ devtoolsPort CONSTANT)
    Q_PROPERTY(QStringList webviewHostMappingRules READ hostMappingRules CONSTANT)

public:
    UbuntuWebPluginContext(QObject* parent = 0);

    QString cacheLocation() const;
    QString dataLocation() const;
    QString formFactor();
    int cacheSizeHint() const;
    QString devtoolsHost();
    int devtoolsPort();
    QStringList hostMappingRules();

Q_SIGNALS:
    void cacheLocationChanged() const;
    void dataLocationChanged() const;
    void cacheSizeHintChanged() const;

private:
    QString m_formFactor;
    QString m_devtoolsHost;
    int m_devtoolsPort;
    QStringList m_hostMappingRules;
    bool m_hostMappingRulesQueried;
};

UbuntuWebPluginContext::UbuntuWebPluginContext(QObject* parent)
    : QObject(parent)
    , m_devtoolsPort(-2)
    , m_hostMappingRulesQueried(false)
{
    connect(QCoreApplication::instance(), SIGNAL(applicationNameChanged()),
            this, SIGNAL(cacheLocationChanged()));
    connect(QCoreApplication::instance(), SIGNAL(applicationNameChanged()),
            this, SIGNAL(dataLocationChanged()));
    connect(QCoreApplication::instance(), SIGNAL(applicationNameChanged()),
            this, SIGNAL(cacheSizeHintChanged()));
}

QString UbuntuWebPluginContext::cacheLocation() const
{
    QDir location(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    if (!location.exists()) {
        QDir::root().mkpath(location.absolutePath());
    }
    return location.absolutePath();
}

QString UbuntuWebPluginContext::dataLocation() const
{
    QDir location(QStandardPaths::writableLocation(QStandardPaths::DataLocation));
    if (!location.exists()) {
        QDir::root().mkpath(location.absolutePath());
    } else {
        // Prior to fixing https://launchpad.net/bugs/1424726, chromium’s cache
        // data was written to the data location. Purge the old cache data.
        QDir(location.absoluteFilePath("Cache")).removeRecursively();
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

int UbuntuWebPluginContext::cacheSizeHint() const
{
    if (QCoreApplication::applicationName() == "webbrowser-app") {
        // Let chromium decide the optimum cache size based on available disk space
        return 0;
    } else {
        // For webapps and other embedders, determine the cache size hint
        // using heuristics based on the disk space (total, and available).
        QStorageInfo storageInfo(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
        const int MB = 1024 * 1024;
        // The total cache size for all apps should not exceed 10% of the total disk space
        int maxSharedCache = storageInfo.bytesTotal() / MB * 0.1;
        // One given app is allowed to use up to 5% o the total cache size
        int maxAppCacheAllowance = maxSharedCache * 0.05;
        // Ensure it never exceeds 200 MB though
        int maxAppCacheAbsolute = qMin(maxAppCacheAllowance, 200);
        // Never use more than 20% of the available disk space
        int maxAppCacheRelative = storageInfo.bytesAvailable() / MB * 0.2;
        // Never set a size hint below 5 MB, as that would result in a very inefficient cache
        return qMax(5, qMin(maxAppCacheAbsolute, maxAppCacheRelative));
    }
}

QStringList UbuntuWebPluginContext::hostMappingRules()
{
    static const QString HOST_MAPPING_RULES_SEP = ",";

    if (!m_hostMappingRulesQueried) {
        const char* HOST_MAPPING_RULES_ENV_VAR = "UBUNTU_WEBVIEW_HOST_MAPPING_RULES";
        if (qEnvironmentVariableIsSet(HOST_MAPPING_RULES_ENV_VAR)) {
            QString rules(qgetenv(HOST_MAPPING_RULES_ENV_VAR));
            // from http://src.chromium.org/svn/trunk/src/net/base/host_mapping_rules.h
            m_hostMappingRules = rules.split(HOST_MAPPING_RULES_SEP);
        }
        m_hostMappingRulesQueried = true;
    }
    return m_hostMappingRules;
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

void UbuntuBrowserPlugin::initializeEngine(QQmlEngine* engine, const char* uri)
{
    Q_UNUSED(uri);

    QQmlContext* context = engine->rootContext();
    context->setContextObject(new UbuntuWebPluginContext(context));

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
