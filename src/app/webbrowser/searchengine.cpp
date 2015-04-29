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

// local
#include "searchengine.h"

// Qt
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QXmlStreamReader>

SearchEngine::SearchEngine(QObject* parent)
    : QObject(parent)
{}

const QStringList& SearchEngine::searchPaths() const
{
    return m_searchPaths;
}

void SearchEngine::setSearchPaths(const QStringList& searchPaths)
{
    if (searchPaths != m_searchPaths) {
        m_searchPaths = searchPaths;
        Q_EMIT searchPathsChanged();
        locateAndParseDescription();
    }
}

const QString& SearchEngine::filename() const
{
    return m_filename;
}

void SearchEngine::setFilename(const QString& filename)
{
    if (filename != m_filename) {
        m_filename = filename;
        Q_EMIT filenameChanged();
        locateAndParseDescription();
    }
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

bool SearchEngine::isValid() const
{
    return !m_searchPaths.isEmpty() &&
           !m_filename.isEmpty() &&
           !m_name.isEmpty() &&
           !m_template.isEmpty();
}

void SearchEngine::locateAndParseDescription()
{
    QString filepath;
    if (!m_filename.isEmpty()) {
        Q_FOREACH(const QString& path, m_searchPaths) {
            QDir dir(path);
            QString filename = m_filename + ".xml";
            if (dir.exists(filename)) {
                filepath = dir.filePath(filename);
                break;
            }
        }
    }

    QString oldName = m_name;
    m_name.clear();
    QString oldDescription = m_description;
    m_description.clear();
    QString oldTemplate = m_template;
    m_template.clear();
    bool wasValid = isValid();

    if (!filepath.isEmpty()) {
        QFile file(filepath);
        if (file.open(QIODevice::ReadOnly)) {
            // Parse OpenSearch description file
            // (http://www.opensearch.org/Specifications/OpenSearch/1.1)
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
    }
    if (m_name != oldName) {
        Q_EMIT nameChanged();
    }
    if (m_description != oldDescription) {
        Q_EMIT descriptionChanged();
    }
    if (m_template != oldTemplate) {
        Q_EMIT urlTemplateChanged();
    }
    if (isValid() != wasValid) {
        Q_EMIT validChanged();
    }
}
