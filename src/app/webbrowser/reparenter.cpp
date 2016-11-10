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

#include <QtCore/QPointer>
#include <QtCore/QVariantMap>
#include <QtQml>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlEngine>
#include <QtQuick/QQuickItem>

Reparenter::Reparenter()
{
}

// Upon deconstruction ensure that all created contexts are destroyed
Reparenter::~Reparenter()
{
    QMap<QPointer<QQmlContext>, QPointer<QObject>>::iterator i;

    for (i = m_contexts.begin(); i != m_contexts.end(); ++i) {
        QPointer<QQmlContext> context = i.key();
        QPointer<QObject> obj = i.value();

        // If there is valid object then delete
        if (obj) {
            delete obj;
        }

        // If there is a valid context then delete
        if (context) {
            delete context;
        }
    }

    m_contexts.clear();  // ensure contexts are removed
}

// Create an object of the given component with the context given
// if no context is given then the context is the instance of this class
// this method is required so that a custom context can be created, so that
// when tabs are moved between Windows and the window is destroyed, its context
// it not also destroyed
QObject *Reparenter::createObject(QQmlComponent *comp, QQuickItem *parent, QVariantMap properties, QQuickItem *contextItem)
{
    // Make context for the object
    QPointer<QQmlContext> context;

    if (contextItem == Q_NULLPTR) {
        // Build context from parent
        context = new QQmlContext(qmlEngine(parent)->rootContext());
        context->setContextObject(parent);
    } else {
        context = new QQmlContext(QQmlEngine::contextForObject(contextItem));
        context->setContextObject(contextItem);
    }

    // Make component
    QPointer<QObject> obj = comp->create(context);

    // Set visual and actual parent
    reparent(qobject_cast<QQuickItem *>(obj), parent);

    // Load properties into object
    for (QString key : properties.keys()) {
        obj->setProperty(key.toStdString().c_str(), properties.value(key));
    }

    // Add to store
    m_contexts.insert(context, obj);

    return obj;
}

// Contexts that have been created by us, must be destroyed by us
// so this helper method destroys the context and object
void Reparenter::destroyContextAndObject(QQuickItem *item)
{
    // Get context for object
    QQmlContext *context = QQmlEngine::contextForObject(item)->parentContext();

    // Remove from store
    m_contexts.remove(context);

    // Disconnect everything
    item->disconnect();

    // Delete context and object
    delete context;
    delete item;
}

// Reparent the actual objects parent and its visual parent
void Reparenter::reparent(QQuickItem *obj, QQuickItem *newParent)
{
    // Set object and visual parent
    obj->setParent(newParent);
    obj->setParentItem(newParent);
}

