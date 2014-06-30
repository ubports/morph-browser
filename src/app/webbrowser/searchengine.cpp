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

// local
#include "searchengine.h"

// Qt
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QXmlStreamReader>

SearchEngine::SearchEngine(const QString& name, QObject* parent)
    : QObject(parent)
    , m_name(DEFAULT_SEARCH_NAME)
    , m_description(DEFAULT_SEARCH_DESC)
    , m_template(DEFAULT_SEARCH_TEMPLATE)
{
    QString searchenginesSubDir("searchengines");
    QString filename = searchenginesSubDir + "/" + name + ".xml";
    m_path = QStandardPaths::locate(QStandardPaths::DataLocation, filename);
    if (!m_path.isEmpty()) {
        parseOpenSearchDescription();
    }
}

SearchEngine::SearchEngine(const SearchEngine& other)
{
    m_path = other.m_path;
    m_name = other.m_name;
    m_description = other.m_description;
    m_template = other.m_template;
}

bool SearchEngine::isValid() const
{
    return (!m_name.isEmpty() && !m_template.isEmpty());
}

const QString& SearchEngine::name() const
{
    return m_name;
}

const QString& SearchEngine::description() const
{
    return m_description;
}

const QString& SearchEngine::urlTemplate() const
{
    return m_template;
}

void SearchEngine::parseOpenSearchDescription()
{
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }
    QXmlStreamReader parser(&file);
    while (!parser.atEnd()) {
        parser.readNext();
        if (parser.isStartElement()) {
            QStringRef name = parser.name();
            if (name == "ShortName") {
                m_name = parser.readElementText();
            } else if (name == "Description") {
                m_description = parser.readElementText();
            } else if (name == "Url") {
                if (parser.attributes().value("type") == "text/html") {
                    m_template = parser.attributes().value("template").toString();
                }
            }
        }
    }
}
