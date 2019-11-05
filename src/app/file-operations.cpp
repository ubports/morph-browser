/*
 * Copyright 2014-2015 Canonical Ltd.
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

#include "file-operations.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QUrl>

FileOperations::FileOperations(QObject* parent)
    : QObject(parent)
{
}

QString FileOperations::baseName(const QString& path) const
{
    return QFileInfo(path).baseName();
}

QString FileOperations::extension(const QString& path) const
{
    return QFileInfo(path).completeSuffix();
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

bool FileOperations::removeDirRecursively(const QUrl& dir) const
{
    return QDir(dir.toLocalFile()).removeRecursively();
}

bool FileOperations::mkpath(const QUrl& path) const
{
    return QDir::root().mkpath(path.toLocalFile());
}

QStringList FileOperations::filesInDirectory(const QUrl& directory,
                                             const QStringList& filters) const
{
    return QDir(directory.toLocalFile()).entryList(filters,
                                                   QDir::Files, QDir::Unsorted);
}
