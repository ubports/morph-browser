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

#ifndef _INTENT_FILTER_H_
#define _INTENT_FILTER_H_

#include <QObject>
#include <QString>
#include <QVariantMap>


class QUrl;
class IntentFilterPrivate;
struct IntentUriDescription;

/**
 * @brief The IntentFilter class
 */
class IntentFilter : public QObject
{
    Q_OBJECT

public:
    IntentFilter(const QString& content,
            QObject *parent = 0);
    ~IntentFilter();

    /**
     * @brief isValidLocalIntentFilterFile
     * @return
     */
    static bool isValidLocalIntentFilterFile(const QString& filename);

    /**
     * @brief isValidIntentDescription
     * @return
     */
    static bool isValidIntentDescription(const IntentUriDescription& );

    /**
     * @brief isValidIntentFilterResult
     * @return
     */
    static bool isValidIntentFilterResult(const QVariantMap& );

    /**
     * @brief apply
     * @return
     */
    Q_INVOKABLE QVariantMap applyFilter(const QString& intentUri);

    /**
     * @brief isValidIntentUri
     * @return
     */
    Q_INVOKABLE bool isValidIntentUri(const QString& intentUri) const;


private:

    IntentFilterPrivate* d_ptr;
    Q_DECLARE_PRIVATE(IntentFilter)
};


struct IntentUriDescription
{
    QString uriPath;

    // optional
    QString host;

    QString package;
    QString action;
    QString category;
    QString component;
    QString scheme;
};

/**
 * @brief parseIntentUri
 * @param intentUri
 * @return
 */
IntentUriDescription parseIntentUri(const QUrl& intentUri);

#endif // _INTENT_FILTER_H_
