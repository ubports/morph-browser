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

#ifndef __BROWSER_APPLICATION_H__
#define __BROWSER_APPLICATION_H__

// Qt
#include <QtCore/QList>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QUrl>
#include <QtWidgets/QApplication>

class QQmlComponent;
class QQmlEngine;
class QQuickWindow;
class QThread;
class WebBrowserWindow;

class BrowserApplication : public QApplication
{
    Q_OBJECT

public:
    BrowserApplication(int& argc, char** argv);
    ~BrowserApplication();

    bool initialize(const QString& qmlFileSubPath);
    int run();

protected:
    virtual void printUsage() const = 0;
    QList<QUrl> urls() const;

    virtual void qmlEngineCreated(QQmlEngine *);

    QStringList m_arguments;
    QQuickWindow* m_window;

private:
    QString appId() const;

    QQmlEngine* m_engine;
    QThread* m_thumbnailUtilsThread;
    QQmlComponent* m_component;
    WebBrowserWindow *m_webbrowserWindowProxy;
};

#endif // __BROWSER_APPLICATION_H__
