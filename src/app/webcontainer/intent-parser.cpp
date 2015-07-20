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

#include "intent-parser.h"

#include <QtCore/QRegularExpression>
#include <QJSEngine>
#include <QJSValue>
#include <QUrl>


namespace {

const char INTENT_SCHEME_STRING[] = "intent";
const char INTENT_START_FRAGMENT_TAG[] = "Intent";
const char INTENT_URI_PACKAGE_PREFIX[] = "package=";
const char INTENT_URI_ACTION_PREFIX[] = "action=";
const char INTENT_URI_CATEGORY_PREFIX[] = "category=";
const char INTENT_URI_COMPONENT_PREFIX[] = "component=";
const char INTENT_URI_SCHEME_PREFIX[] = "scheme=";
const char INTENT_END_FRAGMENT_TAG[] = ";end";

void trimUriSeparator(QString& uriComponent)
{
    uriComponent.remove(QRegExp("^/*")).remove(QRegExp("/*$"));
}

}

IntentUriDescription
parseIntentUri(const QUrl& intentUri)
{
    IntentUriDescription result;
    if (intentUri.scheme() != INTENT_SCHEME_STRING
            || !intentUri.fragment().startsWith(INTENT_START_FRAGMENT_TAG)
            || !intentUri.fragment().endsWith(INTENT_END_FRAGMENT_TAG))
    {
        return result;
    }
    QString host = intentUri.host();
    trimUriSeparator(host);
    QString path = intentUri.path();
    if (intentUri.hasQuery())
    {
        path += "?" + intentUri.query();
        trimUriSeparator(path);
    }
    result.host = host;
    result.uriPath = path;
    QStringList infos = intentUri.fragment().split(";");
    Q_FOREACH(const QString& info, infos)
    {
        if (info.startsWith(INTENT_URI_PACKAGE_PREFIX))
        {
            result.package = info.split(INTENT_URI_PACKAGE_PREFIX)[1];
        }
        else if (info.startsWith(INTENT_URI_ACTION_PREFIX))
        {
            result.action = info.split(INTENT_URI_ACTION_PREFIX)[1];
        }
        else if (info.startsWith(INTENT_URI_CATEGORY_PREFIX))
        {
            result.category = info.split(INTENT_URI_CATEGORY_PREFIX)[1];
        }
        else if (info.startsWith(INTENT_URI_COMPONENT_PREFIX))
        {
            result.component = info.split(INTENT_URI_COMPONENT_PREFIX)[1];
        }
        else if (info.startsWith(INTENT_URI_SCHEME_PREFIX))
        {
            result.scheme = info.split(INTENT_URI_SCHEME_PREFIX)[1];
        }
    }
    return result;
}
