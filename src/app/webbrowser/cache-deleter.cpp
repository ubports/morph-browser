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

#include "cache-deleter.h"

#include <QtConcurrent/QtConcurrentRun>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QFileInfo>
#include <QtCore/QMutexLocker>
#include <QtCore/QString>
#include <QtCore/QStringList>

CacheDeleter::CacheDeleter(QObject* parent)
    : QObject(parent)
{
    connect(&m_clearWatcher, SIGNAL(finished()), SLOT(onCleared()));
}

void CacheDeleter::clear(const QString& cachePath, const QJSValue& callback)
{
    QMutexLocker locker(&m_mutex);

    if (m_clearWatcher.isRunning()) {
        return;
    }

    if (!callback.isUndefined() && !callback.isCallable()) {
        qWarning() << "CacheDeleter::clear: 'callback' is not a function";
        return;
    }
    m_callback = callback;

    m_clearWatcher.setFuture(QtConcurrent::run(this, &CacheDeleter::doClear, cachePath));
}

/*
 * Poor man’s implementation of clearing oxide’s cache directory.
 * Until oxide grows an API to do that (https://launchpad.net/bugs/1260014),
 * this simply deletes selected files in the Cache directory to reclaim
 * space. This heavily relies on the resilience of the cache backend that
 * is expected to cope well with files disappearing under its feet.
 * Note that if cached data was kept in memory, it’s not evicted, so this
 * implementation doesn’t actually clear the cache completely.
 */
void CacheDeleter::doClear(const QString& cachePath)
{
    // This assumes the cache is using chromium’s simple cache backend.
    QStringList nameFilters = QStringList()
            << "0*" << "1*" << "2*" << "3*" << "4*" << "5*" << "6*" << "7*"
            << "8*" << "9*" << "a*" << "b*" << "c*" << "d*" << "e*" << "f*"
            << "index";
    QDir::Filters filters = QDir::Files | QDir::NoDotAndDotDot;
    QFileInfoList files = QDir(cachePath).entryInfoList(nameFilters, filters);
    Q_FOREACH(const QFileInfo& file, files) {
        QFile::remove(file.absoluteFilePath());
    }

    nameFilters = QStringList() << "the-real-index";
    files = QDir(cachePath + "/index-dir").entryInfoList(nameFilters, filters);
    Q_FOREACH(const QFileInfo& file, files) {
        QFile::remove(file.absoluteFilePath());
    }
}

void CacheDeleter::onCleared()
{
    if (!m_callback.isUndefined()) {
        m_callback.call();
        m_callback = QJSValue::UndefinedValue;
    }
}
