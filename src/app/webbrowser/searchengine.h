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

#ifndef __SEARCH_ENGINE_H__
#define __SEARCH_ENGINE_H__

// local
#include "config.h"

// Qt
#include <QtCore/QMetaType>
#include <QtCore/QObject>
#include <QtCore/QString>

class SearchEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QString template READ urlTemplate CONSTANT)

public:
    SearchEngine(const QString& name=DEFAULT_SEARCH_ENGINE, QObject* parent=0);
    SearchEngine(const SearchEngine& other);

    bool isValid() const;
    const QString& name() const;
    const QString& description() const;
    const QString& urlTemplate() const;

private:
    QString m_path;
    QString m_name;
    QString m_description;
    QString m_template;

    void parseOpenSearchDescription();
};

Q_DECLARE_METATYPE(SearchEngine);

#endif // __SEARCH_ENGINE_H__
