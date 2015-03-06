/*
 * Copyright 2014-2015 Canonical Ltd.
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

#include "file-operations.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QUrl>

FileOperations::FileOperations(QObject* parent)
    : QObject(parent)
{
}

bool FileOperations::exists(const QUrl& path) const
{
    // works for both files and directories
    return QFileInfo::exists(path.toLocalFile());
}

bool FileOperations::remove(const QUrl& file) const
{
    return QFile::remove(file.toLocalFile());
}

bool FileOperations::mkpath(const QUrl& path) const
{
    return QDir::root().mkpath(path.toLocalFile());
}
