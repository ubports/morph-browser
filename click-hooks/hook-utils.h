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

#include <QDir>
#include <QHash>
#include <QString>
#include <QStringList>
#include <exception>


namespace HookUtils {

/**
 * Simple optional type wrapper
 */
template <typename T>
class Fallible
{
public:
    explicit Fallible<T>(const T& data, bool is_valid = true)
        : _data(data), _is_valid(is_valid) {}

    bool is_valid() const { return _is_valid; }
    const T& value() const
    {
        if (!is_valid())
        {
            throw std::exception();
        }
        return _data;
    }

private:
    T _data;
    bool _is_valid;
};

/**
 * @brief The WebappHookParser class
 */
class WebappHookParser {
public:
    struct Data
    {
        Data ()
            : shouldDeleteCacheOnUninstall(false)
              , shouldDeleteCookiesOnUninstall(false) {}
        bool shouldDeleteCacheOnUninstall;
        bool shouldDeleteCookiesOnUninstall;
    };
    typedef Fallible<Data> OptionalData;

public:
    OptionalData parseContent(const QString& filename);
private:
    OptionalData parseDocument(const QJsonArray &array);
};

/**
 * @brief Simple POD for click hook files & their parent folders.
 */
struct WebappClickHookInstallDescription
{
    WebappClickHookInstallDescription(
            const QString& folder,
            const QHash<QString, QString>& files)
        : parentFolder(folder), hookFiles(files) {}

    QString parentFolder;
    QHash<QString, QString> hookFiles;
};

/**
 * @brief listWebappClickHookFilesIn
 * @param dir
 * @return
 */
WebappClickHookInstallDescription listWebappClickHookFilesIn(const QDir& dir);

/**
 * @brief getProcessedClickHooksFolder
 * @return
 */
QString getProcessedClickHooksFolder();

/**
 * @brief getClickHooksInstallFolder
 * @return
 */
QString getClickHooksInstallFolder();

/**
 * @brief removeVersionFrom
 * @param appId
 * @return
 */
QString removeVersionFrom(const QString &appId);

/**
 * @brief handleInstalls Detects click package uninstalls and handled what's needed
 * @param alreadyProcessedClickHooks
 * @param currentClickHooks
 */
void handleInstalls(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                   , const WebappClickHookInstallDescription& currentClickHooks);

/**
 * @brief handleUninstall Detects click package uninstalls and handled what's needed
 * @param alreadyProcessedClickHooks
 * @param currentClickHooks
 */
void handleUninstall(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                     , const WebappClickHookInstallDescription& currentClickHooks);

/**
 * @brief handleUpdates
 * @param alreadyProcessedClickHooks
 * @param currentClickHooks
 */
void handleUpdates(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                   , const WebappClickHookInstallDescription& installedClickHooks);

} // namespace HookUtils
