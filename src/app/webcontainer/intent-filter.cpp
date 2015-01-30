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

#include "intent-filter.h"

#include <QtCore/QRegularExpression>
#include <QDebug>
#include <QFile>
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

class IntentFilterPrivate
{
public:

    static const QString DEFAULT_PASS_THROUGH_FILTER;

public:

    IntentFilterPrivate(const QString& content);

    QJSValue evaluate(const IntentUriDescription& intent);
    QJSValue evaluate(const QString& customContent
                      , const IntentUriDescription& intent);

private:

    QJSValue callFunction(
            QJSValue & function
            , const IntentUriDescription& intent);

    QString _content;
    QJSEngine _engine;
    QJSValue _function;

};

// static
const QString IntentFilterPrivate::DEFAULT_PASS_THROUGH_FILTER =
        "(function(intent) { return intent; })";

IntentFilterPrivate::IntentFilterPrivate(const QString& content)
    : _content(content)
{
    if (_content.isEmpty())
    {
        _content = DEFAULT_PASS_THROUGH_FILTER;
    }
    _function = _engine.evaluate(_content);
}

QJSValue IntentFilterPrivate::callFunction(QJSValue & function
                                          , const IntentUriDescription& intent)
{
    if (!function.isCallable())
    {
        qCritical() << "Invalid intent filter function (not callable)";
        return QJSValue();
    }

    QVariantMap o;
    o.insert("scheme", intent.scheme);
    o.insert("uri", intent.uriPath);
    o.insert("host", intent.host);

    QJSValueList jsargs;
    jsargs << _engine.toScriptValue(o);
    return function.call(jsargs);
}

QJSValue IntentFilterPrivate::evaluate(const QString& customContent
                                       , const IntentUriDescription& intent)
{
    QJSValue f = _engine.evaluate(customContent);
    return callFunction(f, intent);
}

QJSValue IntentFilterPrivate::evaluate(const IntentUriDescription& intent)
{
    return callFunction(_function, intent);
}

// static
bool IntentFilter::isValidLocalIntentFilterFile(const QString& filename)
{
    QFile f(filename);
    if (!f.exists() || !f.open(QIODevice::ReadOnly))
    {
        return false;
    }

    // Perform basic validation
    QJSEngine engine;
    QJSValue result = engine.evaluate(QString(f.readAll()), filename);
    return !result.isNull() && result.isCallable();
}

// static
bool IntentFilter::isValidIntentFilterResult(const QVariantMap& result)
{
    return result.contains("scheme")
        && result.value("scheme").canConvert(QVariant::String)
        && result.contains("uri")
        && result.value("uri").canConvert(QVariant::String)
        && result.contains("host")
        && result.value("host").canConvert(QVariant::String);
}

// static
bool IntentFilter::isValidIntentDescription(const IntentUriDescription& intentDescription)
{
    return !intentDescription.uriPath.isEmpty()
        || !intentDescription.package.isEmpty();
}


IntentFilter::IntentFilter(const QString& content, QObject *parent) :
    QObject(parent),
    d_ptr(new IntentFilterPrivate(content))
{
}

IntentFilter::~IntentFilter()
{
    delete d_ptr;
}

QVariantMap IntentFilter::applyFilter(const QString& intentUri)
{
    Q_D(IntentFilter);

    QVariantMap result;
    IntentUriDescription intentDescription =
            parseIntentUri(QUrl::fromUserInput(intentUri));
    if (!isValidIntentDescription(intentDescription))
    {
        return result;
    }
    QJSValue value = d->evaluate(intentDescription);
    if (value.isObject()
            && value.toVariant().canConvert(QVariant::Map))
    {
        QVariantMap r = value.toVariant().toMap();
        if (isValidIntentFilterResult(r))
        {
            result = r;
        }
        else
        {
            // Fallback to a noop
            result = d->evaluate(
                        IntentFilterPrivate::DEFAULT_PASS_THROUGH_FILTER
                        , intentDescription).toVariant().toMap();
        }
    }
    return result;
}

bool IntentFilter::isValidIntentUri(const QString& intentUri) const
{
    // a bit overkill but anyway ...
    return isValidIntentDescription(parseIntentUri(QUrl::fromUserInput(intentUri)));
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
    trimUriSeparator(path);
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
