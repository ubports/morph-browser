/*
 * Copyright 2020 UBports Foundation
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __NOTIFICATIONS_PROXY_H__
#define __NOTIFICATIONS_PROXY_H__

#include <QtCore/QObject>
#include <QJsonObject>

class NotificationsProxy : public QObject
{
    Q_OBJECT

public:
    explicit NotificationsProxy(QObject* parent=0);

    Q_INVOKABLE void setAppId(const QString & appId);
    Q_INVOKABLE void sendNotification(QObject * notificationObject) const;
    Q_INVOKABLE void updateCount() const;
    
private:
    QJsonObject buildMessage(const QString & tag, const QUrl & origin, const QString & title, const QString & body) const;
    QJsonObject buildCard(const QUrl & origin, const QString & title, const QString & body) const;

    QString m_appId;
    bool m_isWebApp;
};

#endif // __NOTIFICATIONS_PROXY_H__
