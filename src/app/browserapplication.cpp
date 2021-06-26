/*
 * Copyright 2013-2017 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// system
#include <cerrno>
#include <cstring>
#include <sys/apparmor.h>

// Qtlangc
#include <QtCore/QMetaObject>
#include <QtCore/QtGlobal>
#include <QtGui/QTouchDevice>
#include <QtNetwork/QNetworkInterface>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlProperty>
#include <QtQml/QtQml>

// local
#include "browserapplication.h"
#include "browser-utils.h"
#include "config.h"
#include "domain-permissions-model.h"
#include "domain-settings-model.h"
#include "domain-settings-sorted-model.h"
#include "domain-settings-user-agents-model.h"
#include "downloads-model.h"
#include "favicon-fetcher.h"
#include "file-operations.h"
#include "input-method-handler.h"
#include "meminfo.h"
#include "mime-database.h"
#include "notifications-proxy.h"
#include "session-storage.h"

BrowserApplication::BrowserApplication(int& argc, char** argv)
    : QApplication(argc, argv)
    , m_engine(0)
    , m_component(0)
    , m_object(nullptr)
{
    m_arguments = arguments();
    m_arguments.removeFirst();
}

BrowserApplication::~BrowserApplication()
{
    delete m_object;
    delete m_component;
    delete m_engine;
}

QString BrowserApplication::inspectorPort() const
{
    QString port;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument == "--inspector") {
            // default port
            port = QString::number(REMOTE_INSPECTOR_PORT);
            break;
        }
        if (argument.startsWith("--inspector=")) {
            port = argument.split("--inspector=")[1];
            break;
        }
    }
    return port;
}

QString BrowserApplication::inspectorHost() const
{
    QString host;
    Q_FOREACH(QHostAddress address, QNetworkInterface::allAddresses()) {
        if (!address.isLoopback() && (address.protocol() == QAbstractSocket::IPv4Protocol)) {
            host = address.toString();
            break;
        }
    }
    return host;
}

#define MAKE_SINGLETON_FACTORY(type) \
    static QObject* type##_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine) { \
        Q_UNUSED(engine); \
        Q_UNUSED(scriptEngine); \
        return new type(); \
    }

MAKE_SINGLETON_FACTORY(BrowserUtils)
MAKE_SINGLETON_FACTORY(DomainPermissionsModel)
MAKE_SINGLETON_FACTORY(DomainSettingsModel)
MAKE_SINGLETON_FACTORY(DownloadsModel)
MAKE_SINGLETON_FACTORY(FileOperations)
MAKE_SINGLETON_FACTORY(MemInfo)
MAKE_SINGLETON_FACTORY(MimeDatabase)
MAKE_SINGLETON_FACTORY(NotificationsProxy)
MAKE_SINGLETON_FACTORY(UserAgentsModel)

bool BrowserApplication::initialize(const QString& qmlFileSubPath
                                    , const QString& appId)
{
    Q_ASSERT(m_object == nullptr);

    if (helpRequested()) {
        printUsage();
        return false;
    }

    if (appId.isEmpty()) {
        qCritical() << "Cannot initialize the runtime environment: "
                       "no application id detected.";
        return false;
    }

    // Ensure that application-specific data is written where it ought to.
    QStringList appIdParts = appId.split('_');

    QCoreApplication::setApplicationName(appIdParts.first());
    QCoreApplication::setOrganizationDomain(QCoreApplication::applicationName());

    // Get also the the first two components of the app ID: <package>_<app>,
    // which is needed by Online Accounts.
    QString unversionedAppId = QStringList(appIdParts.mid(0, 2)).join('_');

    // Ensure only one instance of the app is running.
    // For webapps using the container as a launcher, the predicate that
    // is used to determine if this running instance is a duplicate of
    // a running one, is based on the current APP_ID.
    // The app id is formed as: <package name>_<app name>_<version>

    // Where the <package name> is specified in the the manifest.json as
    // "appName" and is specific for the whole click package.

    // The <app name> portion is based on the desktop file name and is a short
    // app name. This name is meaningful when more than one desktop file is
    // found in a given click package.

    // IMPORTANT:
    // 1. When a click application contains more than one desktop file
    // the bundle is considered a single app from the point of view of the
    // cache and resource file locations. THOSE FILES ARE THEN SHARED between
    // the instances.
    // 2. To make sure that if more than one desktop file is found in a click package,
    // those apps are not considered the same instance, the instance existance predicate
    // is based on the <package name> AND the <app name> detailed above.
    if (m_singleton.run(m_arguments, appId)) {
        connect(&m_singleton, SIGNAL(newInstanceLaunched(const QStringList&)),
                SLOT(onNewInstanceLaunched(const QStringList&)));
    } else {
        return false;
    }

    bool runningConfined = true;
    char* label;
    char* mode;
    if (aa_getcon(&label, &mode) != -1) {
        if (strcmp(label, "unconfined") == 0) {
            runningConfined = false;
        }
        free(label);
    } else if (errno == EINVAL) {
        runningConfined = false;
    }

    QString devtoolsPort = inspectorPort();
    QString devtoolsHost = inspectorHost();
    bool inspectorEnabled = !devtoolsPort.isEmpty();
    if (inspectorEnabled) {
        qputenv("UBUNTU_WEBVIEW_DEVTOOLS_HOST", devtoolsHost.toUtf8());
        qputenv("UBUNTU_WEBVIEW_DEVTOOLS_PORT", devtoolsPort.toUtf8());
    }
    
    // set suru style
    if (qgetenv("QT_QUICK_CONTROLS_STYLE") == QString())
    {
        qputenv("QT_QUICK_CONTROLS_STYLE", "Suru");
    }

    const char* uri = "webbrowsercommon.private";
    qmlRegisterSingletonType<BrowserUtils>(uri, 0, 1, "BrowserUtils", BrowserUtils_singleton_factory);
    qmlRegisterSingletonType<DomainPermissionsModel>(uri, 0, 1, "DomainPermissionsModel", DomainPermissionsModel_singleton_factory);
    qmlRegisterSingletonType<DomainSettingsModel>(uri, 0, 1, "DomainSettingsModel", DomainSettingsModel_singleton_factory);
    qmlRegisterType<DomainSettingsSortedModel>(uri, 0, 1, "DomainSettingsSortedModel");
    qmlRegisterSingletonType<DownloadsModel>(uri, 0, 1, "DownloadsModel", DownloadsModel_singleton_factory);
    qmlRegisterType<FaviconFetcher>(uri, 0, 1, "FaviconFetcher");
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterSingletonType<MemInfo>(uri, 0, 1, "MemInfo", MemInfo_singleton_factory);
    qmlRegisterSingletonType<MimeDatabase>(uri, 0, 1, "MimeDatabase", MimeDatabase_singleton_factory);
    qmlRegisterSingletonType<NotificationsProxy>(uri, 0, 1, "NotificationsProxy", NotificationsProxy_singleton_factory);
    qmlRegisterType<SessionStorage>(uri, 0, 1, "SessionStorage");
    qmlRegisterSingletonType<UserAgentsModel>(uri, 0, 1, "UserAgentsModel", UserAgentsModel_singleton_factory);

    m_engine = new QQmlEngine;
    connect(m_engine, SIGNAL(quit()), SLOT(quit()));
    if (!isRunningInstalled()) {
        m_engine->addImportPath(UbuntuBrowserImportsDirectory());
    }
    qmlEngineCreated(m_engine);

    QQmlContext* context = m_engine->rootContext();
    context->setContextProperty("__runningConfined", runningConfined);
    context->setContextProperty("unversionedAppId", unversionedAppId);

    m_component = new QQmlComponent(m_engine);
    m_component->loadUrl(QUrl::fromLocalFile(qmlFileSubPath));
    if (!m_component->isReady()) {
        qWarning() << m_component->errorString();
        return false;
    }

    m_object = m_component->beginCreate(context);

    QQmlProperty::write(m_object, QStringLiteral("developerExtrasEnabled"), inspectorEnabled);

    bool hasTouchScreen = false;
    Q_FOREACH(const QTouchDevice* device, QTouchDevice::devices()) {
        if (device->type() == QTouchDevice::TouchScreen) {
            hasTouchScreen = true;
        }
    }
    QQmlProperty::write(m_object, QStringLiteral("hasTouchScreen"), hasTouchScreen);

    inputMethodHandler * handler = new inputMethodHandler();
    this->installEventFilter(handler);

    return true;
}

void BrowserApplication::qmlEngineCreated(QQmlEngine*)
{}

int BrowserApplication::run()
{
    Q_ASSERT(m_object != nullptr);
    return exec();
}

QList<QUrl> BrowserApplication::urls() const
{
    QList<QUrl> urls;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (!argument.startsWith("-")) {
            QUrl url = QUrl::fromUserInput(argument);
            if (url.isValid()) {
                urls.append(url);
            }
        }
    }
    return urls;
}

bool BrowserApplication::helpRequested()
{
    return m_arguments.contains("--help") || m_arguments.contains("-h");
}
