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
#include "config.h"
#include "searchengine.h"

// Qt
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QXmlStreamReader>

SearchEngine::SearchEngine(QObject* parent)
    : QObject(parent)
    , m_name(DEFAULT_SEARCH_NAME)
    , m_description(DEFAULT_SEARCH_DESC)
    , m_template(DEFAULT_SEARCH_TEMPLATE)
{
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

        m_name = DEFAULT_SEARCH_NAME;
        m_description = DEFAULT_SEARCH_DESC;
        m_template = DEFAULT_SEARCH_TEMPLATE;

        if (!filename.isEmpty()) {
            QString filepath = QStandardPaths::locate(QStandardPaths::DataLocation,
                                                      "searchengines/" + filename + ".xml");
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
        }

        Q_EMIT nameChanged();
        Q_EMIT descriptionChanged();
        Q_EMIT urlTemplateChanged();
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
