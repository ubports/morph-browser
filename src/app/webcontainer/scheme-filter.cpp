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

#include "scheme-filter.h"

#include <QtCore/QRegularExpression>
#include <QDebug>
#include <QFile>
#include <QJSEngine>
#include <QJSValue>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

#include <QMap>

#include "intent-parser.h"


class SchemeFilterPrivate
{
public:

    static const QString DEFAULT_PASS_THROUGH_FILTER;

public:

    SchemeFilterPrivate(const QMap<QString, QString>& content);

    QJSValue evaluate(const QString & filterFunction, const QUrl& uri);
    QJSValue evaluate(const QUrl& uri);
    QJSValue evaluate(QJSValue & function, const QUrl& uri);
    bool hasFilterFor(const QUrl& uri);

private:

    QJSValue callFunction(
            QJSValue & function
            , const QString& scheme
            , const QString& uri
            , const QString& host);

    QMap<QString, QJSValue> _filterFunctionsPerScheme;
    QJSEngine _engine;
};

// static
const QString SchemeFilterPrivate::DEFAULT_PASS_THROUGH_FILTER =
        "(function(uri) { return uri; })";

SchemeFilterPrivate::SchemeFilterPrivate(const QMap<QString, QString>& content)
{
    Q_FOREACH(QString scheme, content.keys())
    {
        QJSValue v = _engine.evaluate(content[scheme]);
        if (v.isCallable())
        {
            _filterFunctionsPerScheme[scheme] = v;
        }
    }
}

bool SchemeFilterPrivate::hasFilterFor(const QUrl& uri)
{
    return _filterFunctionsPerScheme.contains(uri.scheme());
}

QJSValue SchemeFilterPrivate::callFunction(QJSValue & function
                                           , const QString& scheme
                                           , const QString& path
                                           , const QString& host)
{
    if (!function.isCallable()) {
        qCritical() << "Invalid intent filter function (not callable)";
        return QJSValue();
    }

    QVariantMap o;
    o.insert("scheme", scheme);
    o.insert("path", path);
    o.insert("host", host);

    QJSValueList jsargs;
    jsargs << _engine.toScriptValue(o);
    return function.call(jsargs);
}

QJSValue SchemeFilterPrivate::evaluate(const QString & filterFunction,
                                       const QUrl& uri)
{
    QJSValue f = _engine.evaluate(filterFunction);
    return evaluate(f, uri);
}

QJSValue SchemeFilterPrivate::evaluate(const QUrl& uri)
{
    return evaluate(_filterFunctionsPerScheme[uri.scheme()], uri);
}

QJSValue SchemeFilterPrivate::evaluate(QJSValue & function, const QUrl& uri)
{
    QString scheme;
    QString path;
    QString host;

    if (uri.scheme() == "intent") {
        IntentUriDescription intent = parseIntentUri(uri);

        scheme = intent.scheme;
        path = intent.uriPath;
        host = intent.host;
    }
    else {
        scheme = uri.scheme();
        path = uri.path();
        host = uri.host();
    }

    return callFunction(
                function,
                scheme,
                path,
                host);
}

// static
QMap<QString, QString>
SchemeFilter::parseValidLocalSchemeFilterFile(
            bool & isValid,
            const QString& filename)
{
    QFile f(filename);
    if (!f.exists() || !f.open(QIODevice::ReadOnly)) {
        isValid = false;
        return QMap<QString, QString>();
    }

    QString content = f.readAll();

    QJsonDocument document(QJsonDocument::fromJson(content.toUtf8()));
    if (document.isNull() || document.isEmpty() || !document.isObject()) {
        isValid = false;
        return QMap<QString, QString>();
    }

    QMap<QString, QString> parsedContent;

    QJsonObject root = document.object();
    Q_FOREACH(const QString& k, root.keys()) {
        QJsonValue v = root.value(k);

        if (v.isString()) {
            QJSEngine engine;
            QJSValue result = engine.evaluate(v.toString(), filename);

            if (result.isNull() || !result.isCallable()) {
                isValid = false;
                return QMap<QString, QString>();
            }
            parsedContent[k] = v.toString();
        }
    }

    isValid = true;

    return parsedContent;
}

SchemeFilter::SchemeFilter(const QMap<QString, QString>& content, QObject *parent) :
    QObject(parent),
    d_ptr(new SchemeFilterPrivate(content))
{}

SchemeFilter::~SchemeFilter()
{
    delete d_ptr;
}

bool SchemeFilter::hasFilterFor(const QUrl& uri)
{
    Q_D(SchemeFilter);
    return d->hasFilterFor(uri);
}

QVariantMap SchemeFilter::applyFilter(const QUrl& uri)
{
    Q_D(SchemeFilter);

    if (! hasFilterFor(uri)) {
        return d->evaluate(
                    SchemeFilterPrivate::DEFAULT_PASS_THROUGH_FILTER, uri)
                .toVariant().toMap();
    }

    QJSValue value;

    // Special case to parse schemes we know about & want to provide helpr w/
    value = d->evaluate(uri);

    QVariantMap result;
    if (value.isObject() && value.toVariant().canConvert(QVariant::Map)) {
        result = value.toVariant().toMap();
    }

    return result;
}
