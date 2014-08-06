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

#ifndef __SESSION_STORAGE_H__
#define __SESSION_STORAGE_H__

// Qt
#include <QtCore/QObject>
#include <QtCore/QString>

class SessionStorage : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString dataFile READ dataFile WRITE setDataFile NOTIFY dataFileChanged)

public:
    SessionStorage(QObject* parent = 0);

    const QString& dataFile() const;
    void setDataFile(const QString& dataFile);

    Q_INVOKABLE void store(const QString& data) const;
    Q_INVOKABLE QString retrieve() const;

Q_SIGNALS:
    void dataFileChanged() const;

private:
    QString m_dataFile;
};

#endif // __SESSION_STORAGE_H__
