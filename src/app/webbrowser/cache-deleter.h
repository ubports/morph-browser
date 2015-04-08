/*
 * Copyright 2015 Canonical Ltd.
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

#ifndef __CACHE_DELETER_H__
#define __CACHE_DELETER_H__

#include <QtCore/QFutureWatcher>
#include <QtCore/QMutex>
#include <QtCore/QObject>
#include <QtQml/QJSValue>

class QString;

class CacheDeleter : public QObject
{
    Q_OBJECT

public:
    explicit CacheDeleter(QObject* parent=0);

    Q_INVOKABLE void clear(const QString& cachePath, const QJSValue& callback=QJSValue::UndefinedValue);

private:
    void doClear(const QString& cachePath);

private Q_SLOTS:
    void onCleared();

private:
    QMutex m_mutex;
    QFutureWatcher<void> m_clearWatcher;
    QJSValue m_callback;
};

#endif // __CACHE_DELETER_H__
