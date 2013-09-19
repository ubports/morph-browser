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
#include <QtCore/QStringList>
#include <QtCore/QUrl>

class CommandLineParser : public QObject
{
    Q_OBJECT
    Q_FLAGS(ChromeElementFlag)


public:
    enum ChromeElementFlag
    {
        CHROMELESS = 0x1,
        BACK_FORWARD_BUTTONS = 0x2,
        ACTIVITY_BUTTON = 0x4,
        ADDRESS_BAR = 0x8
    };
    Q_DECLARE_FLAGS(ChromeElementFlags, ChromeElementFlag)


public:
    CommandLineParser(QStringList arguments, QObject* parent=0);

    void printUsage() const;

    bool help() const;

    bool chromeless() const;
    bool fullscreen() const;
    bool maximized() const;

    QUrl url() const;

    bool remoteInspector() const;

    bool webapp() const;
    QString webappName() const;
    QString webappModelSearchPath() const;

    QString appId() const;

    QStringList webappUrlPatterns() const;
    ChromeElementFlags chromeFlags() const;

private:
    bool m_help;
    bool m_fullscreen;
    bool m_maximized;
    QUrl m_url;
    bool m_remoteInspector;
    bool m_webapp;
    QString m_webappName;
    QString m_webappModelSearchPath;
    QString m_appid;
    QStringList m_webappUrlPatterns;
    ChromeElementFlags m_chromeFlags;
};

Q_DECLARE_OPERATORS_FOR_FLAGS(CommandLineParser::ChromeElementFlags)

#endif // __COMMANDLINE_PARSER_H__
