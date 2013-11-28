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

#ifndef __WEBAPP_CONTAINER_H__
#define __WEBAPP_CONTAINER_H__

#include "../browserapplication.h"

// Qt
#include <QString>
#include <QStringList>

class WebappContainer : public BrowserApplication
{
    Q_OBJECT

public:
    WebappContainer(int& argc, char** argv);

    bool initialize();

private:
    virtual void printUsage() const;
    QString webappModelSearchPath() const;
    QString webappName() const;
    QStringList webappUrlPatterns() const;
};

#endif // __WEBAPP_CONTAINER_H__
