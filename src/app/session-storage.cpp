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
    }
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
