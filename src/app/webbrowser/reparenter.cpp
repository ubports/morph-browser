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
 
#include "reparenter.h"

#include <QQuickItem>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>

Reparenter::Reparenter()
{
}

QObject *Reparenter::createObject(QQmlComponent *comp, QQuickItem *contextItem)
{
    if (contextItem == NULL) {
        contextItem = this;
    }

    // Make context
    QQmlContext *context = new QQmlContext(QQmlEngine::contextForObject(contextItem));
    context->setContextObject(contextItem);
    
    // Make component
    return comp->create(context);
}

void Reparenter::destroyContextAndObject(QQuickItem *item)
{
    // Get context for object
    QQmlContext *context = QQmlEngine::contextForObject(item);
    
    // Disconnect everything
    item->disconnect();
    
    // Delete context and object
    delete context->parentContext();
    delete item;
}

void Reparenter::reparent(QQuickItem *obj, QQuickItem *newParent)
{
    // Set object and visual parent    
    obj->setParent(newParent);
    obj->setParentItem(newParent);
}

