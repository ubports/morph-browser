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

#include "url-pattern-utils.h"

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QtGlobal>
#include <QtCore/QRegularExpression>
#include <QtCore/QTextStream>
#include <QtQuick/QQuickWindow>
#include <QtQml/QQmlComponent>

WebappContainer::WebappContainer(int& argc, char** argv)
    : BrowserApplication(argc, argv)
{
}

bool WebappContainer::initialize()
{
    if (BrowserApplication::initialize("webcontainer/webapp-container.qml")) {
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

        bool oxide = withOxide();
        qDebug() << "Using" << (oxide ? "Oxide" : "QtWebkit") << "as the web engine backend";
        m_window->setProperty("oxide", oxide);

        m_window->setProperty("webappUrlPatterns", webappUrlPatterns());

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

void WebappContainer::printUsage() const
{
    QTextStream out(stdout);
    QString command = QFileInfo(QCoreApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--fullscreen] [--maximized] [--inspector] [--app-id=APP_ID] [--homepage=URL] [--webapp[=name]] [--webappModelSearchPath=PATH] [--webappUrlPatterns=URL_PATTERNS] [--enable-back-forward] [--enable-addressbar] [URL]" << endl;
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
    out << "Chrome options (if none specified, no chrome is shown by default):" << endl;
    out << "  --enable-back-forward               enable the display of the back and forward buttons" << endl;
    out << "  --enable-addressbar                 enable the display of the address bar" << endl;
}

QString currentArchitecturePathName()
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

bool WebappContainer::withOxide() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument == "--webkit") {
            // force webkit
            return false;
        }
        if (argument == "--oxide") {
            // force oxide
            return true;
        }
    }

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

QString WebappContainer::webappModelSearchPath() const
{
    Q_FOREACH(const QString& argument, m_arguments) {
        if (argument.startsWith("--webappModelSearchPath=")) {
            return argument.split("--webappModelSearchPath=")[1];
        }
    }
    return QString();
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

                    if (pattern.isEmpty())
                        continue;

                    QString safePattern =
                            UrlPatternUtils::transformWebappSearchPatternToSafePattern(pattern);

                    if ( ! safePattern.isEmpty()) {
                        patterns.append(safePattern);
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
