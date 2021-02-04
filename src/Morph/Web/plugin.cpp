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
#include <QtCore/QtMath>
#include <QtGui/QGuiApplication>
#include <QtGui/QScreen>
#include <QtGui/QWindow>
#include <QtQml>
#include <QtQml/QQmlInfo>

class MorphWebPluginContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString cacheLocation READ cacheLocation NOTIFY cacheLocationChanged)
    Q_PROPERTY(QString dataLocation READ dataLocation NOTIFY dataLocationChanged)
    Q_PROPERTY(qreal screenDiagonal READ screenDiagonal NOTIFY screenDiagonalChanged)
    Q_PROPERTY(int cacheSizeHint READ cacheSizeHint NOTIFY cacheSizeHintChanged)
    Q_PROPERTY(QString webviewDevtoolsDebugHost READ devtoolsHost CONSTANT)
    Q_PROPERTY(int webviewDevtoolsDebugPort READ devtoolsPort CONSTANT)
    Q_PROPERTY(QStringList webviewHostMappingRules READ hostMappingRules CONSTANT)
    Q_PROPERTY(QString ubuntuVersion READ ubuntuVersion CONSTANT)

public:
    MorphWebPluginContext(QObject* parent = 0);

    QString cacheLocation() const;
    QString dataLocation() const;
    qreal screenDiagonal() const;
    int cacheSizeHint() const;
    QString devtoolsHost();
    int devtoolsPort();
    QStringList hostMappingRules();
    QString ubuntuVersion() const;

Q_SIGNALS:
    void cacheLocationChanged() const;
    void dataLocationChanged() const;
    void screenDiagonalChanged() const;
    void cacheSizeHintChanged() const;

private Q_SLOTS:
    void onFocusWindowChanged(QWindow* window);
    void updateScreen();

private:
    qreal m_screenDiagonal; // in millimeters
    QString m_devtoolsHost;
    int m_devtoolsPort;
    QStringList m_hostMappingRules;
    bool m_hostMappingRulesQueried;
};

MorphWebPluginContext::MorphWebPluginContext(QObject* parent)
    : QObject(parent)
    , m_screenDiagonal(0)
    , m_devtoolsPort(-2)
    , m_hostMappingRulesQueried(false)
{
    connect(qApp, SIGNAL(applicationNameChanged()), SIGNAL(cacheLocationChanged()));
    connect(qApp, SIGNAL(applicationNameChanged()), SIGNAL(dataLocationChanged()));
    connect(qApp, SIGNAL(applicationNameChanged()), SIGNAL(cacheSizeHintChanged()));
    updateScreen();
    connect(qApp, SIGNAL(focusWindowChanged(QWindow*)), SLOT(onFocusWindowChanged(QWindow*)));
}

void MorphWebPluginContext::updateScreen()
{
    QWindow* window = qApp->focusWindow();
    if (window) {
        QScreen* screen = window->screen();
        if (screen) {
            QSizeF size = screen->physicalSize();
            qreal diagonal = qSqrt(size.width() * size.width() + size.height() * size.height());
            if (diagonal != m_screenDiagonal) {
                m_screenDiagonal = diagonal;
                Q_EMIT screenDiagonalChanged();
            }
        }
    }
}

QString MorphWebPluginContext::cacheLocation() const
{
    QDir location(QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
    if (!location.exists()) {
        QDir::root().mkpath(location.absolutePath());
    }
    return location.absolutePath();
}

QString MorphWebPluginContext::dataLocation() const
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

qreal MorphWebPluginContext::screenDiagonal() const
{
    return m_screenDiagonal;
}

int MorphWebPluginContext::cacheSizeHint() const
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

QStringList MorphWebPluginContext::hostMappingRules()
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

QString MorphWebPluginContext::devtoolsHost()
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

int MorphWebPluginContext::devtoolsPort()
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

QString MorphWebPluginContext::ubuntuVersion() const
{
    return QStringLiteral(UBUNTU_VERSION);
}

void MorphWebPluginContext::onFocusWindowChanged(QWindow* window)
{
    updateScreen();
    if (window) {
        connect(window, SIGNAL(screenChanged(QScreen*)), SLOT(updateScreen()));
    }
}

void MorphBrowserPlugin::initializeEngine(QQmlEngine* engine, const char* uri)
{
    Q_UNUSED(uri);

    QQmlContext* context = engine->rootContext();
    context->setContextObject(new MorphWebPluginContext(context));

}

void MorphBrowserPlugin::registerTypes(const char* uri)
{
    Q_ASSERT(uri == QLatin1String("Morph.Web"));
    qmlRegisterModule(uri, 0, 1);
}

#include "plugin.moc"
