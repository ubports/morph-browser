/*
 * Copyright 2014 Canonical Ltd.
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

// Qt
#include <QtCore/QFile>
#include <QtCore/QFileInfo>

// local
#include "session-storage.h"

SessionStorage::SessionStorage(QObject* parent)
    : QObject(parent)
    , m_locked(false)
{}

SessionStorage::~SessionStorage()
{
    QString lock = lockFile();
    if (!m_locked && !lock.isEmpty()) {
        QFile::remove(lock);
    }
}

const QString& SessionStorage::dataFile() const
{
    return m_dataFile;
}

void SessionStorage::setDataFile(const QString& dataFile)
{
    if (m_dataFile != dataFile) {
        QString oldLock = lockFile();
        if (!m_locked && !oldLock.isEmpty()) {
            QFile::remove(oldLock);
        }
        m_dataFile = dataFile;
        Q_EMIT dataFileChanged();
        QString lock = lockFile();
        bool locked = QFileInfo::exists(lock);
        m_locked = locked;
        if (!m_locked) {
            QFile(lock).open(QIODevice::WriteOnly);
        }
        if (m_locked != locked) {
            Q_EMIT lockedChanged();
        }
    }
}

// 'locked' means that the session storage file is already in use by another
// instance of the app. There is only one session file for all instances of
// the app, so the first instance locks it and is allowed to save its session,
// whereas other instances discard their sessions when closed.
// This has no effect on devices where there can only be one instance of an
// app at any given time, it’s mostly useful on desktop to avoid instances
// overwriting each other’s sessions.
bool SessionStorage::locked() const
{
    return m_locked;
}

void SessionStorage::store(const QString& data) const
{
    QFile file(m_dataFile);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(data.toUtf8());
        file.close();
    }
}

QString SessionStorage::retrieve() const
{
    QFile file(m_dataFile);
    if (file.open(QIODevice::ReadOnly)) {
        return file.readAll();
    }
    return QString();
}

const QString SessionStorage::lockFile() const
{
    if (!m_dataFile.isEmpty()) {
        return m_dataFile + ".lock";
    }
    return QString();
}
