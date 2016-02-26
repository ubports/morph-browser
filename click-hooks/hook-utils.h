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
 * @brief The WebappHookParser class
 */
class WebappHookParser {
public:
    /*
     * Warning: The values exposed by the Data POD
     * should have default values set to no-ops
     * in case of any parsing failure so that the associated
     * actions are not triggered.
     */
    struct Data
    {
        Data ()
            : shouldDeleteCache(false)
              , shouldDeleteCookies(false) {}
        bool shouldDeleteCache;
        bool shouldDeleteCookies;
    };

    enum ClickLifeCyclePhase {
        CLICK_LIFECYCLE_PHASE_INSTALL,
        CLICK_LIFECYCLE_PHASE_UNINSTALL,
        CLICK_LIFECYCLE_PHASE_UPDATE
    };

public:
    Data parseContent(const QString& filename,
                      ClickLifeCyclePhase clickLifeCyclePhase);
private:
    Data parseDocument(const QJsonArray& array,
                       ClickLifeCyclePhase clickLifeCyclePhase);
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
 * @brief listWebappProcessedClickHookFilesIn
 * @param dir
 * @return
 */
WebappClickHookInstallDescription
listWebappProcessedClickHookFilesIn(const QDir& dir);

/**
 * @brief listWebappInstalledClickHookFilesIn
 * @param dir
 * @return
 */
WebappClickHookInstallDescription
listWebappInstalledClickHookFilesIn(const QDir& dir);

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
QString removeVersionFrom(const QString& appId);

/**
 * @brief handleInstalls Detects click package installs and handled what's needed
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
