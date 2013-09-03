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
    Q_ENUMS(ChromeElementFlags)


public:
    enum ChromeElementFlags
    {
        NO_CHROME_FLAGS = 0,
        CHROMELESS = 0x1,
        BACK_FORWARD_BUTTONS = 0x2,
        ACTIVITY_BUTTON = 0x4,
        ADDRESS_BAR = 0x8
    };


public:
    CommandLineParser(QStringList arguments, QObject* parent=0);

    void printUsage() const;

    bool help() const;

    bool chromeless() const;
    bool fullscreen() const;

    QUrl url() const;

    bool remoteInspector() const;

    bool webapp() const;
    QString webappName() const;

    QString appId() const;

    size_t chrome() const;

private:
    void parseChrome(const QString & argument);

    bool m_help;
    bool m_fullscreen;
    QUrl m_url;
    bool m_remoteInspector;
    bool m_webapp;
    QString m_webappName;
    QString m_appid;
    size_t m_chromeFlags;
};

#endif // __COMMANDLINE_PARSER_H__
