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

// local
#include "commandline-parser.h"
#include "config.h"

// Qt
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QTextStream>

// stdlib
#include <cstdio>

CommandLineParser::CommandLineParser(QStringList arguments, QObject* parent)
    : QObject(parent)
    , m_help(false)
    , m_chromeless(false)
    , m_fullscreen(false)
    , m_url(DEFAULT_HOMEPAGE)
    , m_remoteInspector(false)
    , m_webapp(false)
{
    QStringList args = arguments;
    args.removeFirst();
    if (args.contains("--help") || args.contains("-h")) {
        m_help = true;
    } else {
        QUrl homepage;
        for (int i = args.size() - 1; i >= 0; --i) {
            QString argument = args[i];
            if (argument.startsWith("-")) {
                args.removeAt(i);
                if (argument == "--chromeless") {
                    m_chromeless = true;
                } else if (argument == "--fullscreen") {
                    m_fullscreen = true;
                } else if (argument == "--inspector") {
                    m_remoteInspector = true;
                } else if (argument.startsWith("--webapp")) {
                    // We use the name as a reference instead of the URL with a
                    // subsequent step to match it with a webapp.
                    // TODO: validate that it is fine in all cases
                    // (country dependant, etc…).
                    m_webapp = true;
                    QString tail = argument.split("--webapp")[1];
                    if (!tail.isEmpty() && tail.startsWith("=")) {
                        QString webappName = tail.split("=")[1];
                        tail = QByteArray::fromBase64(webappName.toUtf8()).trimmed();
                        if (!tail.isEmpty()) {
                            m_webappName = tail;
                        }
                    }
                } else if (argument.startsWith("--homepage=")) {
                    homepage = QUrl::fromUserInput(argument.split("--homepage=")[1]);
                } else if (argument.startsWith("--app-id=")) {
                    m_appid = argument.split("--app-id=")[1];
                } else {
                    qWarning() << "WARNING: ignoring unknown switch" << argument;
                }
            }
        }

        if (!homepage.isEmpty()) {
            m_url = homepage;
        } else {
            // the remaining arguments should be URLs
            if (!args.isEmpty()) {
                // consider only the first valid URL, discard the others
                bool foundValidURL = false;
                Q_FOREACH(QString argument, args) {
                    if (foundValidURL) {
                        qWarning() << "WARNING: discarding extra URL" << argument;
                    } else {
                        QUrl url = QUrl::fromUserInput(argument);
                        if (url.isValid()) {
                            m_url = url;
                            foundValidURL = true;
                        } else {
                            qWarning() << "WARNING: ignoring malformed URL" << argument;
                        }
                    }
                }
            }
        }
    }
}

void CommandLineParser::printUsage() const
{
    QTextStream out(stdout);
    QString command = QFileInfo(QCoreApplication::applicationFilePath()).fileName();
    out << "Usage: " << command << " [-h|--help] [--chromeless] [--fullscreen] [--homepage=URL] [URL]" << endl;
    out << "Options:" << endl;
    out << "  -h, --help       display this help message and exit" << endl;
    out << "  --chromeless     do not display any chrome (web application mode)" << endl;
    out << "  --fullscreen     display full screen" << endl;
    out << "  --homepage=URL   override any URL passed as an argument" << endl;
    out << "  --inspector      run a remote inspector on port " << REMOTE_INSPECTOR_PORT << endl;
    out << "  --webapp[=name]  launch the browser as a webapp trying to match it by name with an installed webapp integration script (if any)" << endl;
    out << "  --app-id=APP_ID  run the application with a specific APP_ID" << endl;
}

QString CommandLineParser::appId() const
{
    return m_appid;
}

bool CommandLineParser::help() const
{
    return m_help;
}

bool CommandLineParser::chromeless() const
{
    return m_chromeless;
}

bool CommandLineParser::fullscreen() const
{
    return m_fullscreen;
}

QUrl CommandLineParser::url() const
{
    return m_url;
}

bool CommandLineParser::remoteInspector() const
{
    return m_remoteInspector;
}

bool CommandLineParser::webapp() const
{
    return m_webapp;
}

QString CommandLineParser::webappName() const
{
    return m_webappName;
}
