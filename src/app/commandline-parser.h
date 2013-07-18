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

#ifndef __COMMANDLINE_PARSER_H__
#define __COMMANDLINE_PARSER_H__

// Qt
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QUrl>

class CommandLineParser : public QObject
{
    Q_OBJECT

public:
    CommandLineParser(QStringList arguments, QObject* parent=0);

    void printUsage() const;

    bool help() const;

    bool chromeless() const;
    bool fullscreen() const;

    QUrl url() const;

    QString desktopFileHint() const;

    bool remoteInspector() const;

private:
    bool m_help;
    bool m_chromeless;
    bool m_fullscreen;
    QUrl m_url;
    QString m_desktopFileHint;
    bool m_remoteInspector;
};

#endif // __COMMANDLINE_PARSER_H__
