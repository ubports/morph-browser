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

#ifndef __WEBBROWSER_APP_H__
#define __WEBBROWSER_APP_H__

#include <QtWidgets/QApplication>

class QQmlComponent;
class QQmlEngine;
class QQuickWindow;

class CommandLineParser;

class WebBrowserApp : public QApplication
{
    Q_OBJECT

public:
    WebBrowserApp(int& argc, char** argv);
    ~WebBrowserApp();

    bool initialize();
    int run();

private:
    CommandLineParser* m_arguments;
    QQmlEngine* m_engine;
    QQmlComponent* m_component;
    QQuickWindow* m_window;
};

#endif // __WEBBROWSER_APP_H__
