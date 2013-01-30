/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
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
                } else if (argument.startsWith("--homepage=")) {
                    homepage = QUrl::fromUserInput(argument.split("--homepage=")[1]);
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
                // consider only the first one, discard the others
                QUrl url = QUrl::fromUserInput(args.first());
                if (url.isValid()) {
                    m_url = url;
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
