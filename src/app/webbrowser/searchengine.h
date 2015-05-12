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

#ifndef __SEARCH_ENGINE_H__
#define __SEARCH_ENGINE_H__

// Qt
#include <QtCore/QObject>
#include <QtCore/QString>

class SearchEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString filename READ filename WRITE setFilename NOTIFY filenameChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
    Q_PROPERTY(QString urlTemplate READ urlTemplate NOTIFY urlTemplateChanged)
    Q_PROPERTY(QString suggestionsUrlTemplate READ suggestionsUrlTemplate NOTIFY suggestionsUrlTemplateChanged)

public:
    SearchEngine(QObject* parent=0);

    const QString& filename() const;
    void setFilename(const QString& filename);

    const QString& name() const;
    const QString& description() const;
    const QString& urlTemplate() const;
    const QString& suggestionsUrlTemplate() const;

Q_SIGNALS:
    void filenameChanged() const;
    void nameChanged() const;
    void descriptionChanged() const;
    void urlTemplateChanged() const;
    void suggestionsUrlTemplateChanged() const;

private:
    QString m_filename;
    QString m_name;
    QString m_description;
    QString m_template;
    QString m_suggestionsTemplate;
};

#endif // __SEARCH_ENGINE_H__
