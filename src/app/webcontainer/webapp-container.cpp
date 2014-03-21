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

#include "cookiestore.h"
#include "sqlitecookiestore.h"
#include "onlineaccountscookiestore.h"

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QRegularExpression>
#include <QtCore/QTextStream>
#include <QtQml/QQmlEngine>
#include <QtQml>
#include <QtQuick/QQuickWindow>

static const char privateModuleUri[] = "webcontainer.private";

WebappContainer::WebappContainer(int& argc, char** argv)
    : BrowserApplication(argc, argv)
{
}

bool WebappContainer::initialize()
{
    if (BrowserApplication::initialize("webcontainer/webapp-container.qml",
                                       BrowserApplication::BeginCreation)) {
        QString searchPath = webappModelSearchPath();
        if (!searchPath.isEmpty())
        {
            QDir searchDir(searchPath);
            searchDir.makeAbsolute();
            if (searchDir.exists()) {
                m_window->setProperty("webappModelSearchPath", searchDir.path());
            }
        }
        QString name = webappName();
        m_window->setProperty("webappName", name);
        m_window->setProperty("backForwardButtonsVisible", m_arguments.contains("--enable-back-forward"));
        m_window->setProperty("addressBarVisible", m_arguments.contains("--enable-addressbar"));
        m_window->setProperty("webappUrlPatterns", webappUrlPatterns());
        m_window->setProperty("accountProvider", accountProvider());
        // When a webapp is being launched by name, the URL is pulled from its 'homepage'.
        if (name.isEmpty()) {
            QList<QUrl> urls = this->urls();
            if (!urls.isEmpty()) {
                m_window->setProperty("url", urls.first());
            }
        }

        m_component->completeCreate();
        return true;
    } else {
        return false;
    }
}

void WebappContainer::qmlEngineCreated(QQmlEngine * engine)
{
    registerCookieQmlTypes(engine);
}

void WebappContainer::registerCookieQmlTypes(QQmlEngine * engine)
{
    if (engine)
    {
        qmlRegisterType<CookieStore>(privateModuleUri, 0, 1, "CookieStore");
        qmlRegisterType<SqliteCookieStore>(privateModuleUri, 0, 1, "SqliteCookieStore");
        qmlRegisterType<OnlineAccountsCookieStore>(privateModuleUri, 0, 1, "OnlineAccountsCookieStore");
    }
}

void WebappContainer::printUsage() const
{
    QTextStream out(stdout);
    QString command = QFileInfo(QCoreApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--fullscreen] [--maximized] [--inspector] "
                                   "[--app-id=APP_ID] [--homepage=URL] [--webapp[=name]] "
                                   "[--webappModelSearchPath=PATH] [--webappUrlPatterns=URL_PATTERNS] "
                                   "[--accountProvider=PROVIDER_NAME] "
                                   "[--enable-back-forward] [--enable-addressbar] [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help                          display this help message and exit" << endl;
    out << "  --fullscreen                        display full screen" << endl;
    out << "  --maximized                         opens the application maximized" << endl;
    out << "  --inspector                         run a remote inspector on port " << REMOTE_INSPECTOR_PORT << endl;
    out << "  --app-id=APP_ID                     run the application with a specific APP_ID" << endl;
    out << "  --homepage=URL                      override any URL passed as an argument" << endl;
    out << "  --webapp[=name]                     try to match the webapp by name with an installed integration script (if any)" << endl;
    out << "  --webappModelSearchPath=PATH        alter the search path for installed webapps and set it to PATH. PATH can be an absolute or path relative to CWD" << endl;
    out << "  --webappUrlPatterns=URL_PATTERNS    list of comma-separated url patterns (wildcard based) that the webapp is allowed to navigate to" << endl;
    out << "  --accountProvider=PROVIDER_NAME     Online account provider for the application if the application is to reuse a local account." << endl;
    out << "Chrome options (if none specified, no chrome is shown by default):" << endl;
    out << "  --enable-back-forward               enable the display of the back and forward buttons" << endl;
    out << "  --enable-addressbar                 enable the display of the address bar" << endl;
}

QString WebappContainer::webappModelSearchPath() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webappModelSearchPath=")) {
            return argument.split("--webappModelSearchPath=")[1];
        }
    }
    return QString();
}

QString WebappContainer::accountProvider() const
{
    QString accountProvider;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--accountProvider=")) {
            accountProvider = argument.split("--accountProvider=")[1];
            break;
        }
    }
    return accountProvider;
}

QString WebappContainer::webappName() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webapp=")) {
            // We use the name as a reference instead of the URL with a subsequent step to match it with a webapp.
            // TODO: validate that it is fine in all cases (country dependent, etc…).
            QString name = argument.split("--webapp=")[1];
            return QByteArray::fromBase64(name.toUtf8()).trimmed();
        }
    }
    return QString();
}

/**
 * Tests for the validity of a given webapp url pattern. It follows
 *  the following grammar:
 *
 * <url-pattern> := <scheme>://<host><path>
 * <scheme> := 'http' | 'https'
 * <host> := '*' <any char except '/' and '.'>+ <hostpart> <hostpart>+
 * <hostpart> := '.' <any char except '/', '*', '?' and '.'>+
 * <path> := '/' <any chars>
 *
 * @param pattern pattern that is to be tested for validity
 * @return true if the url is valid, false otherwise
 */
static bool isValidWebappUrlPattern(const QString& pattern)
{
    static QRegularExpression grammar("^http(s|s\\?)?://[^\\.]+\\.[^\\.\\*\\?]+\\.[^\\.\\*\\?]+(\\.[^\\.\\*\\?/]+)*/.*$");
    return grammar.match(pattern).hasMatch();
}


QStringList WebappContainer::webappUrlPatterns() const
{
    QStringList patterns;
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webappUrlPatterns=")) {
            QString tail = argument.split("--webappUrlPatterns=")[1];
            if (!tail.isEmpty()) {
                QStringList includePatterns = tail.split(",");
                Q_FOREACH(const QString& includePattern, includePatterns) {
                    QString pattern = includePattern.trimmed();
                    if (!pattern.isEmpty() && isValidWebappUrlPattern(pattern)) {
                        QRegularExpression urlRe("(.+://)([^/]+)(.+)");
                        QRegularExpressionMatch match = urlRe.match(pattern);
                        if (match.hasMatch())
                        {
                            // We make a distinction between the wildcard found in the
                            //  hostname part and the one found later. The former being more
                            //  restricted and should not be replaced by the same regexp pattern
                            //  as the latter.
                            // A less restrictive hostname pattern might lead to the following
                            //  situation where e.g.
                            // http://bady.guy.com/phishing.ebay.com/
                            // matches
                            // https?://*.ebay.com/*
                            QString scheme = match.captured(1);
                            QString hostname = match.captured(2).replace("*", "[^\\./]*");
                            QString tail = match.captured(3).replace("*", "[^\\s]*");

                            // reconstruct
                            patterns.append(QString("%1%2%3").arg(scheme).arg(hostname).arg(tail));
                        }
                    } else {
                        qDebug() << "Ignoring empty or invalid webapp URL pattern:" << pattern;
                    }
                }
            }
            break;
        }
    }
    return patterns;
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
