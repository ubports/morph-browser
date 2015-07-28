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

#ifndef _SCHEME_FILTER_H_
#define _SCHEME_FILTER_H_

#include <QObject>
#include <QMap>
#include <QString>
#include <QUrl>
#include <QVariantMap>


class SchemeFilterPrivate;

/**
 * @brief The SchemeFilter class
 */
class SchemeFilter : public QObject
{
    Q_OBJECT

public:
    SchemeFilter(const QMap<QString, QString>& content,
                QObject *parent = 0);
    ~SchemeFilter();

    /**
     * @brief isValidLocalSchemeFilterFile
     * @return
     */
    static QMap<QString, QString> parseValidLocalSchemeFilterFile(
            bool & isValid,
            const QString& filename);

    /**
     * @brief apply
     * @return
     */
    Q_INVOKABLE QVariantMap applyFilter(const QUrl& uri);

    /**
     * @brief apply
     * @return
     */
    Q_INVOKABLE bool hasFilterFor(const QUrl& uri);


private:

    SchemeFilterPrivate* d_ptr;
    Q_DECLARE_PRIVATE(SchemeFilter)
};

#endif // _SCHEME_FILTER_H_
