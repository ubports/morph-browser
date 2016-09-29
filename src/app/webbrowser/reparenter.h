/*
 * Copyright 2016 Canonical Ltd.
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

#ifndef __REPARENTER_H__
#define __REPARENTER_H__

#include <QObject>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickItem>

class Reparenter : public QQuickItem
{
    Q_OBJECT

public:
    Reparenter();
    
    Q_INVOKABLE QObject *createObject(QQmlComponent *comp, QQuickItem *contextItem=NULL);
    Q_INVOKABLE void destroyContextAndObject(QQuickItem *item);
    Q_INVOKABLE void reparent(QQuickItem *obj, QQuickItem *newParent);
};

#endif // __REPARENTER_H__

