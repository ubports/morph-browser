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

#ifndef __UBUNTU_BROWSER_H__
#define __UBUNTU_BROWSER_H__

#include <QtCore/QObject>

class QApplication;
class QQuickView;

class UbuntuBrowser : public QObject
{
    Q_OBJECT

public:
    UbuntuBrowser(QObject* parent=0);
    ~UbuntuBrowser();

    bool initialize(int& argc, char** argv);
    int run();

private Q_SLOTS:
    void onTitleChanged();

private:
    QApplication* m_application;
    QQuickView* m_view;
    bool m_fullscreen;
};

#endif // __UBUNTU_BROWSER_H__
