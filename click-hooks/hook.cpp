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

#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QString>

#include "hook-utils.h"


int main(int argc, char ** argv)
{
    QCoreApplication app(argc, argv);

    if (app.arguments().count() != 1)
    {
        qWarning() << "Invalid hook argument count";
        return EXIT_FAILURE;
    }

    QString processedClickHooksFolder =
            HookUtils::getProcessedClickHooksFolder();
    if (!QDir(processedClickHooksFolder).exists())
    {
        QDir().mkpath(processedClickHooksFolder);
    }

    HookUtils::WebappClickHookInstallDescription alreadyProcessedClickHooks =
            HookUtils::listWebappProcessedClickHookFilesIn(
                processedClickHooksFolder);

    HookUtils::WebappClickHookInstallDescription installedClickHooks =
            HookUtils::listWebappInstalledClickHookFilesIn(
                HookUtils::getClickHooksInstallFolder());

    HookUtils::handleInstalls(
                alreadyProcessedClickHooks,
                installedClickHooks);

    HookUtils::handleUpdates(
                alreadyProcessedClickHooks,
                installedClickHooks);

    HookUtils::handleUninstall(
                alreadyProcessedClickHooks,
                installedClickHooks);

    return EXIT_SUCCESS;
}
