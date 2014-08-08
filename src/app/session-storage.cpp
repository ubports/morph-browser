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

// local
#include "session-storage.h"

SessionStorage::SessionStorage(QObject* parent)
    : QObject(parent)
{}

const QString& SessionStorage::dataFile() const
{
    return m_dataFile;
}

void SessionStorage::setDataFile(const QString& dataFile)
{
    if (m_dataFile != dataFile) {
        m_dataFile = dataFile;
        Q_EMIT dataFileChanged();
        bool locked = false;
        if (m_lock) {
            locked = m_lock->isLocked();
        }
        if (!m_dataFile.isEmpty()) {
            m_lock.reset(new QLockFile(m_dataFile + ".lock"));
            m_lock->setStaleLockTime(0);
            m_lock->tryLock();
            if (locked != m_lock->isLocked()) {
                Q_EMIT lockedChanged();
            }
        } else {
            m_lock.reset();
            if (locked) {
                Q_EMIT lockedChanged();
            }
        }
    }
}

// 'locked' means that the session storage file is in use by this instance
// of the app. There is only one session file for all instances of the app,
// so the first instance locks it and is allowed to save its session, whereas
// other instances discard their sessions when closed.
// This has no effect on devices where there can only be one instance of an
// app at any given time, it’s mostly useful on desktop to avoid instances
// overwriting each other’s sessions.
bool SessionStorage::locked() const
{
    if (m_lock) {
        return m_lock->isLocked();
    }
    return false;
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
