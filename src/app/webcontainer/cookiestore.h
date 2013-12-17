/*
 * Copyright 2013 Canonical Ltd.
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

#ifndef __COOKIESTORE_H__
#define __COOKIESTORE_H__

#include <QObject>
#include <QtCore/QList>
#include <QtCore/QString>
#include <QDateTime>
#include <QString>
#include <QMap>

typedef QMap<QString, QString> Cookies;
Q_DECLARE_METATYPE(Cookies);


class CookieStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Cookies cookies READ cookies WRITE setCookies NOTIFY cookiesChanged)
    Q_PROPERTY(QDateTime timeStamp READ timeStamp NOTIFY timeStampChanged)


public:

    CookieStore(QObject *parent = 0);

    Cookies cookies() const;
    void setCookies(Cookies);

    QDateTime timeStamp() const;

    Q_INVOKABLE void moveFrom (const CookieStore * store);

Q_SIGNALS:

    void moved(bool);
    void cookiesChanged();
    void timeStampChanged();

private:

    virtual Cookies doGetCookies() const;
    virtual void doSetCookies(Cookies);

private:

    QDateTime _timeStamp;
};


#endif // __COOKIESTORE_H__

