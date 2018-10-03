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

QString stringFromClickLifeCyclePhase(
        HookUtils::WebappHookParser::ClickLifeCyclePhase phase)
{
    using namespace HookUtils;
    switch(phase) {
    case WebappHookParser::CLICK_LIFECYCLE_PHASE_INSTALL:
        return "install";
        break;
    case WebappHookParser::CLICK_LIFECYCLE_PHASE_UNINSTALL:
        return "uninstall";
        break;
    case WebappHookParser::CLICK_LIFECYCLE_PHASE_UPDATE:
        return "update";
        break;
    }
    return QString();
}

void executeHookDirectives(const QString& hookFilename,
                           HookUtils::WebappHookParser::ClickLifeCyclePhase phase) {
    QFileInfo fileInfo(hookFilename);
    if (!fileInfo.exists() || !fileInfo.isFile())
    {
        qDebug() << "Cannot execute directives for" << hookFilename;
        return;
    }

    qDebug() << "Handling" << hookFilename;

    HookUtils::WebappHookParser webappHookParser;
    HookUtils::WebappHookParser::Data data =
            webappHookParser.parseContent(
                hookFilename,
                phase);

    QString appIdNoVersion = fileInfo.fileName();

    if (data.shouldDeleteCache)
    {
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
                 + "/" + shortAppIdFromUnversionedAppId(appIdNoVersion));
        dir.removeRecursively();

        qDebug() << "Removing cache from" << dir.absolutePath();
    }
    if (data.shouldDeleteCookies)
    {
        QDir dir(QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                 + "/" + shortAppIdFromUnversionedAppId(appIdNoVersion));
        dir.removeRecursively();

        qDebug() << "Removing cookies from" << dir.absolutePath();
    }
}

}


namespace HookUtils {


WebappHookParser::Data
WebappHookParser::parseContent(const QString& filename,
                               ClickLifeCyclePhase clickLifeCyclePhase)
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

    return parseDocument(
                document.array(),
                clickLifeCyclePhase);
}

WebappHookParser::Data
WebappHookParser::parseDocument(const QJsonArray& array,
                                ClickLifeCyclePhase clickLifeCyclePhase)
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

    QString phase = stringFromClickLifeCyclePhase(clickLifeCyclePhase);
    if (JSON_OBJECT_VALIDATE(rootObject,phase,isObject))
    {
        const QString DELETE_COOKIES = "delete-cookies";
        const QString DELETE_CACHE = "delete-cache";

        QJsonObject directiveObject =
                rootObject.value(phase).toObject();
        if (JSON_OBJECT_VALIDATE(directiveObject,DELETE_COOKIES,isBool))
        {
            result.shouldDeleteCookies =
                    directiveObject.value(DELETE_COOKIES).toBool();
        }

        if (JSON_OBJECT_VALIDATE(directiveObject,DELETE_CACHE,isBool))
        {
            result.shouldDeleteCache =
                    directiveObject.value(DELETE_CACHE).toBool();
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

        executeHookDirectives(hookFilename,
                              WebappHookParser::CLICK_LIFECYCLE_PHASE_INSTALL);

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

        executeHookDirectives(hookFilename,
                              WebappHookParser::CLICK_LIFECYCLE_PHASE_UNINSTALL);

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

        executeHookDirectives(hookFilename,
                              WebappHookParser::CLICK_LIFECYCLE_PHASE_UPDATE);

        qDebug() << "Updating " << destination;

        if (QFile::exists(destination))
        {
            QFile::remove(destination);
        }

        QFile::copy(hookFilename, destination);
    }
}


}
