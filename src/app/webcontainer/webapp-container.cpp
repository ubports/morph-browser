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

#include "config.h"
#include "webapp-container.h"

#include "chrome-cookie-store.h"
#include "scheme-filter.h"
#include "local-cookie-store.h"
#include "online-accounts-cookie-store.h"
#include "session-utils.h"
#include "url-pattern-utils.h"
#include "webapp-container-helper.h"


// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QRegularExpression>
#include <QtCore/QSettings>
#include <QtCore/QStandardPaths>
#include <QtCore/QTextStream>
#include <QtCore/QtGlobal>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlProperty>
#include <QtQml>
#include <QtQuick/QQuickWindow>

#include <stdlib.h>

static const char privateModuleUri[] = "webcontainer.private";

namespace
{

/* Hack to clear the local data of the webapp, when it's integrated with OA:
 * https://bugs.launchpad.net/bugs/1371659
 * This is needed because cookie sets from different accounts might not
 * completely overwrite each other, and therefore we end up with an
 * inconsistent cookie jar. */
static void clearCookiesHack(const QString &provider)
{
    if (provider.isEmpty()) {
        qWarning() << "--clear-cookies only works with an accountProvider" << endl;
        return;
    }

    /* check both ~/.local/share and ~/.cache, as the data will eventually be
     * moving from the first to the latter.
     */
    QStringList baseDirs;
    baseDirs << QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    baseDirs << QStandardPaths::writableLocation(QStandardPaths::CacheLocation);

    Q_FOREACH(const QString &baseDir, baseDirs) {
        QDir dir(baseDir);
        dir.removeRecursively();
    }
}

}

const QString WebappContainer::URL_PATTERN_SEPARATOR = ",";
const QString WebappContainer::LOCAL_SCHEME_FILTER_FILENAME = "local-scheme-filter.js";


WebappContainer::WebappContainer(int& argc, char** argv):
    BrowserApplication(argc, argv),
    m_accountSwitcher(false),
    m_storeSessionCookies(false),
    m_backForwardButtonsVisible(false),
    m_addressBarVisible(false),
    m_localWebappManifest(false),
    m_openExternalUrlInOverlay(false),
    m_webappContainerHelper(new WebappContainerHelper()),
    m_fullscreen(false),
    m_maximized(false)
{
}

QString WebappContainer::appId() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--app-id=")) {
            return argument.split("--app-id=")[1];
        }
    }
    return QString();
}

bool WebappContainer::initialize()
{
    if (!helpRequested() && qgetenv("APP_ID").isEmpty()) {
        QString id = appId();
        if (id.isEmpty()) {
            qCritical() << "The application has been launched with no "
                          "explicit or system provided app id. "
                          "An application id can be set by using the --app-id "
                          "command line parameter and setting it to a unique "
                          "application specific value or using the APP_ID environment "
                          "variable.";
            return false;
        }
        qputenv("APP_ID", id.toUtf8());
    }

    earlyEnvironment();

QString qmlfile;
    const QString filePath = QLatin1String("share/webapp-ng/webcontainer/webapp-container.qml");
    QStringList paths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
    paths.prepend(QDir::currentPath());
    paths.prepend(QCoreApplication::applicationDirPath());
    Q_FOREACH (const QString &path, paths) {
        QString myPath = path + QLatin1Char('/') + filePath;
        if (QFile::exists(myPath)) {
            qmlfile = myPath;
            break;
        }
    }
    // sanity check
    if (qmlfile.isEmpty()) {
        qFatal("File: %s does not exist at any of the standard paths!", qPrintable(filePath));
}
    if (BrowserApplication::initialize(qmlfile, QStringLiteral("webapp-ng"))) {
        //QtWebEngine::initialize();

        parseCommandLine();
        parseExtraConfiguration();

        if (m_localWebappManifest)
            m_webappModelSearchPath = ".";

        if (!m_webappModelSearchPath.isEmpty())
        {
            QDir searchDir(m_webappModelSearchPath);
            searchDir.makeAbsolute();
            if (searchDir.exists()) {
                QQmlProperty::write(m_object, QStringLiteral("webappModelSearchPath"), searchDir.path());
            }
        }
        if ( ! m_localCookieStoreDbPath.isEmpty()) {
            QQmlProperty::write(m_object, QStringLiteral("localCookieStoreDbPath"), m_localCookieStoreDbPath);
        }

        QQmlProperty::write(m_object, QStringLiteral("webappName"), m_webappName);
        QFileInfo iconInfo(m_webappIcon);
        QUrl iconUrl;
        if (iconInfo.isReadable()) {
            iconUrl = QUrl::fromLocalFile(iconInfo.absoluteFilePath());
        }
        QQmlProperty::write(m_object, QStringLiteral("webappIcon"), iconUrl);
        QQmlProperty::write(m_object, QStringLiteral("backForwardButtonsVisible"), m_backForwardButtonsVisible);
        QQmlProperty::write(m_object, QStringLiteral("chromeVisible"), m_addressBarVisible);
        QQmlProperty::write(m_object, QStringLiteral("accountProvider"), m_accountProvider);
        QQmlProperty::write(m_object, QStringLiteral("accountSwitcher"), m_accountSwitcher);
        QQmlProperty::write(m_object, QStringLiteral("openExternalUrlInOverlay"), m_openExternalUrlInOverlay);
        QQmlProperty::write(m_object, QStringLiteral("defaultVideoCaptureCameraPosition"), m_defaultVideoCaptureCameraPosition);
        QQmlProperty::write(m_object, QStringLiteral("webappUrlPatterns"), m_webappUrlPatterns);
        QQmlContext* context = m_engine->rootContext();
        if (m_storeSessionCookies) {
            QString sessionCookieMode = SessionUtils::firstRun(m_webappName) ?
                QStringLiteral("persistent") : QStringLiteral("restored");
            qDebug() << "Setting session cookie mode to" << sessionCookieMode;
            QQmlProperty::write(m_object, QStringLiteral("webContextSessionCookieMode"), sessionCookieMode);
        }

        context->setContextProperty("webappContainerHelper", m_webappContainerHelper.data());

        if ( ! m_popupRedirectionUrlPrefixPattern.isEmpty()) {
            const QString WEBAPP_CONTAINER_DO_NOT_FILTER_PATTERN_URL_ENV_VAR =
                qgetenv("WEBAPP_CONTAINER_DO_NOT_FILTER_PATTERN_URL");
            QQmlProperty::write(
                m_object, QStringLiteral("popupRedirectionUrlPrefixPattern"),
                WEBAPP_CONTAINER_DO_NOT_FILTER_PATTERN_URL_ENV_VAR == "1"
                    ? m_popupRedirectionUrlPrefixPattern
                    : UrlPatternUtils::transformWebappSearchPatternToSafePattern(
                        m_popupRedirectionUrlPrefixPattern, false));
        }

        if (!m_userAgentOverride.isEmpty()) {
            QQmlProperty::write(m_object, QStringLiteral("localUserAgentOverride"), m_userAgentOverride);
        }

        // Experimental, unsupported API, to override the webview
        QFileInfo overrideFile("webview-override.qml");
        if (overrideFile.exists()) {
            QQmlProperty::write(m_object, QStringLiteral("webviewOverrideFile"),
                                QUrl::fromLocalFile(overrideFile.absoluteFilePath()));
        }

        const QString WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY_ENV_VAR =
            qgetenv("WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY");
        if (WEBAPP_CONTAINER_BLOCK_OPEN_URL_EXTERNALLY_ENV_VAR == "1") {
            QQmlProperty::write(m_object, QStringLiteral("blockOpenExternalUrls"), true);
        }

        bool runningLocalApp = false;
        QList<QUrl> urls = this->urls();
        if (!urls.isEmpty()) {
            QUrl homeUrl = urls.last();
            QQmlProperty::write(m_object, QStringLiteral("url"), homeUrl);
            if (UrlPatternUtils::isLocalHtml5ApplicationHomeUrl(homeUrl)) {
                qDebug() << "Started as a local application container.";
                runningLocalApp = true;
            }
        } else if (m_webappModelSearchPath.isEmpty()
                   && m_webappName.isEmpty()) {
            qCritical() << "No starting homepage provided";
            return false;
        }

        // Otherwise, assume that the homepage will come from a locally defined
        // webapp-properties.json file pulled from the webapp model element
        // or from a default local system install (if any).

        QQmlProperty::write(m_object, QStringLiteral("runningLocalApplication"), runningLocalApp);

        // Handle the invalid runtime conditions for the local apps
        if (runningLocalApp && !isValidLocalApplicationRunningContext()) {
            qCritical() << "Cannot run a local HTML5 application, invalid command line flags detected.";
            return false;
        }

        // Handle an optional scheme handler filter. The default *catch all* filter does nothing.
        setupLocalSchemeFilterIfAny(context, m_webappModelSearchPath);

        if (qEnvironmentVariableIsSet("WEBAPP_CONTAINER_BLOCKER_DISABLED")
                && QString(qgetenv("WEBAPP_CONTAINER_BLOCKER_DISABLED")) == "1") {
            QQmlProperty::write(m_object, QStringLiteral("popupBlockerEnabled"), false);
        }

        QQmlProperty::write(m_object, QStringLiteral("forceFullscreen"), m_fullscreen);
        QQmlProperty::write(m_object, QStringLiteral("startMaximized"), m_maximized);

        m_component->completeCreate();

        return true;
    } else {
        return false;
    }
}

void WebappContainer::setupLocalSchemeFilterIfAny(QQmlContext* context, const QString& webappSearchPath)
{
    if(!context) {
        return;
    }

    QDir searchPath(webappSearchPath.isEmpty()
                    ? QDir::currentPath()
                    : webappSearchPath);

    bool hasValidLocalSchemeFilterFile = false;

    QMap<QString, QString> content =
            SchemeFilter::parseValidLocalSchemeFilterFile(
                hasValidLocalSchemeFilterFile,
                searchPath.filePath(LOCAL_SCHEME_FILTER_FILENAME));

    if (hasValidLocalSchemeFilterFile) {
        qDebug() << "Using local scheme filter file:"
                 << LOCAL_SCHEME_FILTER_FILENAME;
    }

    m_schemeFilter.reset(new SchemeFilter(content));

    context->setContextProperty("webappSchemeFilter", m_schemeFilter.data());
}

bool WebappContainer::isValidLocalApplicationRunningContext() const
{
    return m_webappModelSearchPath.isEmpty() &&
        m_popupRedirectionUrlPrefixPattern.isEmpty() &&
        m_webappUrlPatterns.isEmpty() &&
        m_webappName.isEmpty();
}

void WebappContainer::qmlEngineCreated(QQmlEngine* engine)
{
    if (engine) {
        qmlRegisterType<ChromeCookieStore>(privateModuleUri, 0, 1,
                                           "ChromeCookieStore");
        qmlRegisterType<LocalCookieStore>(privateModuleUri, 0, 1,
                                           "LocalCookieStore");
        qmlRegisterType<OnlineAccountsCookieStore>(privateModuleUri, 0, 1,
                                                   "OnlineAccountsCookieStore");
    }
}

void WebappContainer::printUsage() const
{
    QTextStream out(stdout);
    QString command = QFileInfo(QCoreApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help]"
       " [--fullscreen]"
       " [--maximized]"
       " [--inspector]"
       " [--app-id=APP_ID]"
       " [--homepage=URL]"
       " [--webapp=name]"
       " [--name=NAME]"
       " [--icon=PATH]"
       " [--webappModelSearchPath=PATH]"
       " [--webappUrlPatterns=URL_PATTERNS]"
       " [--accountProvider=PROVIDER_NAME]"
       " [--accountSwitcher]"
       " [--enable-back-forward]"
       " [--enable-addressbar]"
       " [--store-session-cookies]"
       " [--user-agent-string=USER_AGENT]"
       " [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help                          display this help message and exit" << endl;
    out << "  --fullscreen                        display full screen" << endl;
    out << "  --local-webapp-manifest             configure the webapp assuming that it has a local manifest.json file" << endl;
    out << "  --maximized                         opens the application maximized" << endl;
    out << "  --inspector[=PORT]                  run a remote inspector on a specified port or " << REMOTE_INSPECTOR_PORT << " as the default port" << endl;
    out << "  --app-id=APP_ID                     run the application with a specific APP_ID" << endl;
    out << "  --homepage=URL                      override any URL passed as an argument" << endl;
    out << "  --webapp=name                       try to match the webapp by name with an installed integration script" << endl;
    out << "  --name=NAME                         display name of the webapp, shown in the splash screen" << endl;
    out << "  --icon=PATH                         Icon to be shown in the splash screen. PATH can be an absolute or path relative to CWD" << endl;
    out << "  --webappModelSearchPath=PATH        alter the search path for installed webapps and set it to PATH. PATH can be an absolute or path relative to CWD" << endl;
    out << "  --webappUrlPatterns=URL_PATTERNS    list of comma-separated url patterns (wildcard based) that the webapp is allowed to navigate to" << endl;
    out << "  --accountProvider=PROVIDER_NAME     Online account provider for the application if the application is to reuse a local account." << endl;
    out << "  --accountSwitcher                   enable switching between different Online Accounts identities" << endl;
    out << "  --store-session-cookies             store session cookies on disk" << endl;
    out << "  --enable-media-hub-audio            enable media-hub for audio playback" << endl;
    out << "  --user-agent-string=USER_AGENT      overrides the default User Agent with the provided one." << endl;
    out << "  --open-external-url-in-overlay      if url patterns are defined, all external urls are opened in overlay instead of browser" << endl;

    // The options should be kept in sync with:
    // http://bazaar.launchpad.net/~oxide-developers/oxide/oxide.trunk/view/head:/qt/quick/api/oxideqquickglobal.cc#L43
    out << "  --camera-capture-default=position   set a default for the camera capture device in W3C Media API, 'position' should be"
                                                 " 'frontface', 'backface' or 'none'. If 'none' is selected the default"
                                                 " selection mechanism applied in Oxide is used. If this command line option"
                                                 " is not used, the default is set to 'frontface'. If the position is not found"
                                                 " the behavior is the same as if the option was not set."<< endl;

    out << "Chrome options (if none specified, no chrome is shown by default):" << endl;
    out << "  --enable-back-forward               enable the display of the back and forward buttons (implies --enable-addressbar)" << endl;
    out << "  --enable-addressbar                 enable the display of a minimal chrome (favicon and title)" << endl;
}

void WebappContainer::earlyEnvironment()
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--enable-media-hub-audio")) {
            qputenv("OXIDE_ENABLE_MEDIA_HUB_AUDIO", QString("1").toLocal8Bit().constData());
        }
    }
}

void WebappContainer::parseCommandLine()
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webappModelSearchPath=")) {
            m_webappModelSearchPath = argument.split("--webappModelSearchPath=")[1];
        } else if (argument.startsWith("--webapp=")) {
            // We use the name as a reference instead of the URL with a subsequent step to match it with a webapp.
            // TODO: validate that it is fine in all cases (country dependent, etc…).
            QString name = argument.split("--webapp=")[1];
            m_webappName = QByteArray::fromBase64(name.toUtf8()).trimmed();
        } else if (argument.startsWith("--name=")) {
            m_webappName = argument.split("--name=")[1];
        } else if (argument.startsWith("--icon=")) {
            m_webappIcon = argument.split("--icon=")[1];
        } else if (argument.startsWith("--webappUrlPatterns=")) {
            QString tail = argument.split("--webappUrlPatterns=")[1];
            if (!tail.isEmpty()) {
                QStringList includePatterns = tail.split(URL_PATTERN_SEPARATOR);
                m_webappUrlPatterns = UrlPatternUtils::filterAndTransformUrlPatterns(includePatterns);
            }
        } else if (argument.startsWith("--accountProvider=")) {
            m_accountProvider = argument.split("--accountProvider=")[1];
        } else if (argument == "--accountSwitcher") {
            m_accountSwitcher = true;
        } else if (argument == "--clear-cookies") {
            qWarning() << argument << " is an unsupported option: it can be removed without notice..." << endl;
            clearCookiesHack(m_accountProvider);
        } else if (argument == "--store-session-cookies") {
            m_storeSessionCookies = true;
        } else if (argument == "--enable-back-forward") {
            m_backForwardButtonsVisible = true;
        } else if (argument == "--enable-addressbar") {
            m_addressBarVisible = true;
        } else if (argument == "--local-webapp-manifest") {
            m_localWebappManifest = true;
        } else if (argument.startsWith("--popup-redirection-url-prefix=")) {
            m_popupRedirectionUrlPrefixPattern = argument.split("--popup-redirection-url-prefix=")[1];
        } else if (argument.startsWith("--local-cookie-db-path=")) {
            m_localCookieStoreDbPath = argument.split("--local-cookie-db-path=")[1];
        } else if (argument.startsWith("--user-agent-string=")) {
            m_userAgentOverride = argument.split("--user-agent-string=")[1];
        } else if (argument == "--open-external-url-in-overlay") {
            m_openExternalUrlInOverlay = true;
        } else if (argument.startsWith("--camera-capture-default=")) {
            m_defaultVideoCaptureCameraPosition = argument.split("--camera-capture-default=")[1];
        } else if (argument == QStringLiteral("--fullscreen")) {
            m_fullscreen = true;
        } else if (argument == QStringLiteral("--maximized")) {
            m_maximized = true;
        }
    }
}

void WebappContainer::parseExtraConfiguration()
{
    // Add potential extra url patterns not listed in the command line
    m_webappUrlPatterns.append(
                UrlPatternUtils::filterAndTransformUrlPatterns(
                    getExtraWebappUrlPatterns().split(URL_PATTERN_SEPARATOR)));
}

QString WebappContainer::getExtraWebappUrlPatterns() const
{
    static const QString EXTRA_APP_URL_PATTERNS_CONF_FILENAME =
            "extra-url-patterns.conf";

    QString extraUrlPatternsFilename =
            QString("%1/%2")
                .arg(QStandardPaths::writableLocation(QStandardPaths::DataLocation))
                .arg(EXTRA_APP_URL_PATTERNS_CONF_FILENAME);

    QString extraPatterns;
    QFileInfo f(extraUrlPatternsFilename);
    if (f.exists() && f.isReadable())
    {
        QSettings extraUrlPatternsSetting(f.absoluteFilePath(), QSettings::IniFormat);
        extraUrlPatternsSetting.beginGroup("Extra Patterns");

        QVariant patternsValue = extraUrlPatternsSetting.value("Patterns");

        // The line can contain comma separated args Patterns=1,2,3. In this case
        // QSettings interprets this as a StringList instead of giving us
        // the raw value.
        if (patternsValue.type() == QVariant::StringList)
             extraPatterns = patternsValue.toStringList().join(",");
        else
            extraPatterns = patternsValue.toString();

        if ( ! extraPatterns.isEmpty())
        {
            qDebug() << "Found extra url patterns to be added to the list of allowed urls: "
                     << extraPatterns;
        }
        extraUrlPatternsSetting.endGroup();
    }
    return extraPatterns;
}

bool WebappContainer::isValidLocalResource(const QString& resourceName) const
{
    QFileInfo info(resourceName);
    return info.isFile() && info.exists();
}

bool WebappContainer::shouldNotValidateCommandLineUrls() const
{
    return qEnvironmentVariableIsSet("WEBAPP_CONTAINER_SHOULD_NOT_VALIDATE_CLI_URLS")
            && QString(qgetenv("WEBAPP_CONTAINER_SHOULD_NOT_VALIDATE_CLI_URLS")) == "1";
}

QList<QUrl> WebappContainer::urls() const
{
    QList<QUrl> urls;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (!argument.startsWith("-")) {
            // This is used for testing to avoid having existing
            // resources to run against.
            if (shouldNotValidateCommandLineUrls()) {
                urls.append(argument.startsWith("file://")
                            ? argument
                            : (QString("file://") + argument));
                continue;
            }

            QUrl url;
            if (isValidLocalResource(argument)) {
                url = QUrl::fromLocalFile(QFileInfo(argument).absoluteFilePath());
            } else {
                url = QUrl::fromUserInput(argument);
            }
            if (url.isValid()) {
                urls.append(url);
            }
        }
    }
    return urls;
}

void WebappContainer::onNewInstanceLaunched(const QStringList& arguments) const
{
    QVariantList urls;
    Q_FOREACH(const QString& argument, arguments) {
        if (!argument.startsWith(QStringLiteral("-"))) {
            QUrl url = QUrl::fromUserInput(argument);
            if (url.isValid()) {
                urls.append(url);
            }
        }
    }
    QMetaObject::invokeMethod(m_object, "openUrls", Q_ARG(QVariant, QVariant(urls)));
    QMetaObject::invokeMethod(m_object, "requestActivate");
}

int main(int argc, char** argv)
{
    qputenv("QTWEBENGINE_DISABLE_SANDBOX","1");
    qputenv("QT_WEBENGINE_DISABLE_GPU","1");
    qputenv("QT_SCALE_FACTOR", "2");

    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    WebappContainer app(argc, argv);
    if (app.initialize()) {
        return app.run();
    } else {
        return 0;
    }
}
