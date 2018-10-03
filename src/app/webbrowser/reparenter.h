/*
 * Copyright 2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __REPARENTER_H__
#define __REPARENTER_H__

#include <QtCore/QMap>
#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtCore/QVariantMap>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlContext>
#include <QtQuick/QQuickItem>

class Reparenter : public QObject
{
    Q_OBJECT

public:
    Reparenter();
    ~Reparenter();

    Q_INVOKABLE QObject *createObject(QQmlComponent *comp, QQuickItem *parent, QVariantMap properties={}, QQuickItem *contextItem=Q_NULLPTR);
    Q_INVOKABLE void destroyContextAndObject(QQuickItem *item);
    Q_INVOKABLE void reparent(QQuickItem *obj, QQuickItem *newParent);
private:
    QMap<QPointer<QQmlContext>, QPointer<QObject>> m_contexts;
};

#endif // __REPARENTER_H__

