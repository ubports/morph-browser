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

#include "hook-utils.h"

#include <QDateTime>
#include <QDebug>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>


namespace {

QString shortAppIdFromUnversionedAppId(const QString& appId)
{
    QStringList components = appId.split('_');
    components.removeLast();
    return components.join('_');
}

}


namespace HookUtils {


WebappHookParser::Data
WebappHookParser::parseContent(const QString& filename)
{
    QFileInfo info(filename);
    if (!info.exists() || !info.isFile() || !info.isReadable())
    {
        return Data();
    }

    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
    {
        qWarning() << "Cannot open webapp hook: " << filename;
        return Data();
    }

    QJsonDocument document(QJsonDocument::fromJson(file.readAll()));
    if (document.isNull() || document.isEmpty() || !document.isArray()) {
        return Data();
    }

    return parseDocument(document.array());
}

WebappHookParser::Data
WebappHookParser::parseDocument(const QJsonArray& array)
{
    Data result;
    if (array.count() == 0
            || !array.at(0).isObject())
    {
        return result;
    }

    QJsonObject rootObject = array.at(0).toObject();

#define JSON_OBJECT_VALIDATE(o,key,predicate) \
    o.contains(key) && o.value(key).predicate()

    const QString UNINSTALL_KEY = "uninstall";
    if (JSON_OBJECT_VALIDATE(rootObject,UNINSTALL_KEY,isObject))
    {
        const QString UNINSTALL_DELETE_COOKIES = "delete-cookies";
        const QString UNINSTALL_DELETE_CACHE = "delete-cache";

        QJsonObject uninstallObject =
                rootObject.value(UNINSTALL_KEY).toObject();
        if (JSON_OBJECT_VALIDATE(uninstallObject,UNINSTALL_DELETE_COOKIES,isBool))
        {
            result.shouldDeleteCookiesOnUninstall =
                    uninstallObject.value(UNINSTALL_DELETE_COOKIES).toBool();
        }

        if (JSON_OBJECT_VALIDATE(uninstallObject,UNINSTALL_DELETE_CACHE,isBool))
        {
            result.shouldDeleteCacheOnUninstall =
                    uninstallObject.value(UNINSTALL_DELETE_CACHE).toBool();
        }
    }
#undef JSON_OBJECT_VALIDATE

    return result;
}

WebappClickHookInstallDescription
listWebappProcessedClickHookFilesIn(const QDir& dir)
{
    WebappClickHookInstallDescription
            description(dir.absolutePath(), QHash<QString, QString>());

    Q_FOREACH(const QFileInfo& fileInfo, dir.entryInfoList())
    {
        if (fileInfo.isFile())
        {
            QString filename = fileInfo.fileName();
            description.hookFiles[filename] = filename;
        }
    }
    return description;
}

WebappClickHookInstallDescription
listWebappInstalledClickHookFilesIn(const QDir& dir)
{
    WebappClickHookInstallDescription
            description(dir.absolutePath(), QHash<QString, QString>());

    const QString WEBAPP_CLICK_HOOK_FILE_EXT = "webapp";
    Q_FOREACH(const QFileInfo& fileInfo, dir.entryInfoList())
    {
        if (fileInfo.suffix() == WEBAPP_CLICK_HOOK_FILE_EXT)
        {
            description.hookFiles[removeVersionFrom(fileInfo.completeBaseName())] =
                    fileInfo.fileName();
        }
    }
    return description;
}

QString
getProcessedClickHooksFolder()
{
    QString result = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
            + "/webapp-container";
    if (!qgetenv("WEBAPPCONTAINER_PROCESSED_HOOKS_FOLDER").isNull())
    {
        result = QString(qgetenv("WEBAPPCONTAINER_PROCESSED_HOOKS_FOLDER"));
    }
    return result;
}

QString
getClickHooksInstallFolder()
{
    QString result = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
            + "/webapp-container";
    if (!qgetenv("WEBAPPCONTAINER_INSTALLED_HOOKS_FOLDER").isNull())
    {
        result = QString(qgetenv("WEBAPPCONTAINER_INSTALLED_HOOKS_FOLDER"));
    }
    return result;
}

QString removeVersionFrom(const QString& appId)
{
    QStringList components = appId.split('_');
    if (components.count() != 3)
    {
        return appId;
    }
    components.removeLast();
    return components.join('_');
}

void handleInstalls(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                   , const WebappClickHookInstallDescription& installedClickHooks)
{
    QStringList newlyInstalledClickPackages =
            installedClickHooks.hookFiles.keys().toSet().subtract(
                alreadyProcessedClickHooks.hookFiles.keys().toSet()).toList();

    if (newlyInstalledClickPackages.isEmpty())
    {
        qDebug() << "Nothing to install.";
        return;
    }

    Q_FOREACH(const QString& webappClickHook, newlyInstalledClickPackages)
    {
        QString hookFilename =
                installedClickHooks.parentFolder + "/"
                + installedClickHooks.hookFiles[webappClickHook];

        QFileInfo hookFileInfo(hookFilename);
        QString appIdNoVersion = removeVersionFrom(hookFileInfo.completeBaseName());

        QString destination = QString("%1/%2").
            arg(alreadyProcessedClickHooks.parentFolder).arg(appIdNoVersion);

        qDebug() << "Installing: " << destination;

        QFile::copy(hookFilename, destination);
    }

}

void handleUninstall(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                     , const WebappClickHookInstallDescription& currentClickHooks)
{
    WebappHookParser webappHookParser;
    QStringList deletedClickPackages =
            alreadyProcessedClickHooks.hookFiles.keys().toSet().subtract(
                currentClickHooks.hookFiles.keys().toSet()).toList();

    if (deletedClickPackages.count() == 0)
    {
        qDebug() << "Nothing to delete.";
        return;
    }

    Q_FOREACH(const QString& webappClickHook, deletedClickPackages)
    {
        QString hookFilename =
                alreadyProcessedClickHooks.parentFolder + "/" + webappClickHook;

        WebappHookParser::Data data =
                webappHookParser.parseContent(hookFilename);

        QFileInfo fileInfo(hookFilename);
        QString appIdNoVersion = fileInfo.fileName();

        if (data.shouldDeleteCacheOnUninstall)
        {
            QDir dir(QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
                     + "/" + shortAppIdFromUnversionedAppId(appIdNoVersion));
            dir.removeRecursively();
        }
        if (data.shouldDeleteCookiesOnUninstall)
        {
            QDir dir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                     + "/" + shortAppIdFromUnversionedAppId(appIdNoVersion));
            dir.removeRecursively();
        }

        qDebug() << "Uninstalling: " << hookFilename;

        QFile::remove(hookFilename);
    }
}

void handleUpdates(const WebappClickHookInstallDescription& alreadyProcessedClickHooks
                   , const WebappClickHookInstallDescription& installedClickHooks)
{
    QStringList foundClickHooks =
            alreadyProcessedClickHooks.hookFiles.keys().toSet().intersect(
                installedClickHooks.hookFiles.keys().toSet()).toList();
    if (foundClickHooks.count() == 0)
    {
        qDebug() << "Nothing to update.";
        return;
    }

    Q_FOREACH(const QString& webappClickHook, foundClickHooks)
    {
        QString hookFilename =
                installedClickHooks.parentFolder + "/"
                + installedClickHooks.hookFiles[webappClickHook];

        QFileInfo hookFileInfo(hookFilename);
        QString appIdNoVersion = removeVersionFrom(hookFileInfo.completeBaseName());

        QString destination = QString("%1/%2").
            arg(alreadyProcessedClickHooks.parentFolder).arg(appIdNoVersion);

        QFileInfo destinationInfo(destination);
        if (destinationInfo.exists() &&
            destinationInfo.lastModified() >= hookFileInfo.lastModified()) {
            continue;
        }

        qDebug() << "Updating " << destination;

        if (QFile::exists(destination))
        {
            QFile::remove(destination);
        }

        QFile::copy(hookFilename, destination);
    }
}


}
