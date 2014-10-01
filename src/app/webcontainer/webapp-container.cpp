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

#include "config.h"
#include "webapp-container.h"

#include "chrome-cookie-store.h"
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
#include <QtCore/QtGlobal>
#include <QtCore/QRegularExpression>
#include <QtCore/QTextStream>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQml>
#include <QtQuick/QQuickWindow>

#include <QStandardPaths>
#include <QSettings>

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

static QString currentArchitecturePathName()
{
#if defined(Q_PROCESSOR_X86_32)
    return QLatin1String("i386-linux-gnu");
#elif defined(Q_PROCESSOR_X86_64)
    return QLatin1String("x86_64-linux-gnu");
#elif defined(Q_PROCESSOR_ARM)
    return QLatin1String("arm-linux-gnueabihf");
#else
#error Unable to determine target architecture
#endif
}

static bool canUseOxide()
{
    // Use a runtime hint to transparently know if oxide
    // can be used as a backend without the user/dev having
    // to update its app or change something in the Exec args.
    // Version 1.1 of ubuntu apparmor policy allows this file to
    // be accessed whereas v1.0 only knows about qtwebkit.
    QString oxideHintLocation =
        QString("/usr/lib/%1/oxide-qt/oxide-renderer")
            .arg(currentArchitecturePathName());

    return QFile(oxideHintLocation).open(QIODevice::ReadOnly);
}

}

const QString WebappContainer::URL_PATTERN_SEPARATOR = ",";


WebappContainer::WebappContainer(int& argc, char** argv):
    BrowserApplication(argc, argv),
    m_withOxide(canUseOxide()),
    m_storeSessionCookies(false),
    m_backForwardButtonsVisible(false),
    m_addressBarVisible(false),
    m_localWebappManifest(false),
    m_webappContainerHelper(new WebappContainerHelper())
{
}


bool WebappContainer::initialize()
{
    if (BrowserApplication::initialize("webcontainer/webapp-container.qml")) {
        parseCommandLine();
        parseExtraConfiguration();

        if (m_localWebappManifest)
            m_webappModelSearchPath = ".";

        if (!m_webappModelSearchPath.isEmpty())
        {
            QDir searchDir(m_webappModelSearchPath);
            searchDir.makeAbsolute();
            if (searchDir.exists()) {
                m_window->setProperty("webappModelSearchPath", searchDir.path());
            }
        }
        if ( ! m_localCookieStoreDbPath.isEmpty()) {
            m_window->setProperty("localCookieStoreDbPath", m_localCookieStoreDbPath);
        }

        m_window->setProperty("webappName", m_webappName);
        m_window->setProperty("backForwardButtonsVisible", m_backForwardButtonsVisible);
        m_window->setProperty("chromeVisible", m_addressBarVisible);
        m_window->setProperty("accountProvider", m_accountProvider);

        qDebug() << "Using" << (m_withOxide ? "Oxide" : "QtWebkit") << "as the web engine backend";
        m_window->setProperty("oxide", m_withOxide);

        m_window->setProperty("webappUrlPatterns", m_webappUrlPatterns);
        QQmlContext* context = m_engine->rootContext();
        if (m_storeSessionCookies) {
            QString sessionCookieMode = SessionUtils::firstRun(m_webappName) ?
                QStringLiteral("persistent") : QStringLiteral("restored");
            qDebug() << "Setting session cookie mode to" << sessionCookieMode;
            context->setContextProperty("webContextSessionCookieMode", sessionCookieMode);
        }

        context->setContextProperty("webappContainerHelper", m_webappContainerHelper.data());

        if ( ! m_popupRedirectionUrlPrefix.isEmpty()) {
            m_window->setProperty("popupRedirectionUrlPrefix", m_popupRedirectionUrlPrefix);
        }

        // Experimental, unsupported API, to override the webview
        QFileInfo overrideFile("webview-override.qml");
        if (overrideFile.exists()) {
            m_window->setProperty("webviewOverrideFile", QUrl::fromLocalFile(overrideFile.absoluteFilePath()));
        }

        // When a webapp is being launched by name, the URL is pulled from its 'homepage'.
        if (m_webappName.isEmpty()) {
            QList<QUrl> urls = this->urls();
            if (!urls.isEmpty()) {
                m_window->setProperty("url", urls.last());
            } else if (m_webappModelSearchPath.isEmpty()) {
                return false;
            }
            // Otherwise, assume that the homepage will come from a locally defined
            // webapp-properties.json file pulled from the webapp model element.
        }

        m_component->completeCreate();

        return true;
    } else {
        return false;
    }
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
       " [--webappModelSearchPath=PATH]"
       " [--webappUrlPatterns=URL_PATTERNS]"
       " [--accountProvider=PROVIDER_NAME]"
       " [--enable-back-forward]"
       " [--enable-addressbar]"
       " [--store-session-cookies]"
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
    out << "  --webappModelSearchPath=PATH        alter the search path for installed webapps and set it to PATH. PATH can be an absolute or path relative to CWD" << endl;
    out << "  --webappUrlPatterns=URL_PATTERNS    list of comma-separated url patterns (wildcard based) that the webapp is allowed to navigate to" << endl;
    out << "  --accountProvider=PROVIDER_NAME     Online account provider for the application if the application is to reuse a local account." << endl;
    out << "  --store-session-cookies             store session cookies on disk" << endl;
    out << "Chrome options (if none specified, no chrome is shown by default):" << endl;
    out << "  --enable-back-forward               enable the display of the back and forward buttons (implies --enable-addressbar)" << endl;
    out << "  --enable-addressbar                 enable the display of a minimal chrome (favicon and title)" << endl;
}

void WebappContainer::parseCommandLine()
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument == "--webkit") {
            // force webkit
            m_withOxide = false;
        } else if (argument == "--oxide") {
            // force oxide
            m_withOxide = true;
        } else if (argument.startsWith("--webappModelSearchPath=")) {
            m_webappModelSearchPath = argument.split("--webappModelSearchPath=")[1];
        } else if (argument.startsWith("--webapp=")) {
            // We use the name as a reference instead of the URL with a subsequent step to match it with a webapp.
            // TODO: validate that it is fine in all cases (country dependent, etc…).
            QString name = argument.split("--webapp=")[1];
            m_webappName = QByteArray::fromBase64(name.toUtf8()).trimmed();
        } else if (argument.startsWith("--webappUrlPatterns=")) {
            QString tail = argument.split("--webappUrlPatterns=")[1];
            if (!tail.isEmpty()) {
                QStringList includePatterns = tail.split(URL_PATTERN_SEPARATOR);
                m_webappUrlPatterns = UrlPatternUtils::filterAndTransformUrlPatterns(includePatterns);
            }
        } else if (argument.startsWith("--accountProvider=")) {
            m_accountProvider = argument.split("--accountProvider=")[1];
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
            m_popupRedirectionUrlPrefix = argument.split("--popup-redirection-url-prefix=")[1];;
        } else if (argument.startsWith("--local-cookie-db-path=")) {
            m_localCookieStoreDbPath = argument.split("--local-cookie-db-path=")[1];;
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

int main(int argc, char** argv)
{
    WebappContainer app(argc, argv);
    if (app.initialize()) {
        return app.run();
    } else {
        return 0;
    }
}
