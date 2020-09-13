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

#include "notifications-proxy.h"
#include "pushclient/pushclient.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QtWebEngineCore/QWebEngineNotification>

NotificationsProxy::NotificationsProxy(QObject* parent) : QObject(parent)
{
    m_appId = QString();
    m_isWebApp = false;
}

void NotificationsProxy::setAppId(const QString &appId)
{
    m_appId = appId;
    PushClient::instance()->setAppId(m_appId);
    m_isWebApp = ! m_appId.startsWith("_");
}

void NotificationsProxy::sendNotification(QObject * notificationObject) const
{
    QWebEngineNotification * notification = qobject_cast<QWebEngineNotification *>(notificationObject);
    QJsonObject message = buildMessage(notification->tag(), notification->origin(), notification->title(), notification->message());
    PushClient::instance()->send(message);
}

void NotificationsProxy::updateCount() const
{
    PushClient::instance()->updateCount();
}

QJsonObject NotificationsProxy::buildMessage(const QString & tag, const QUrl & origin, const QString & title, const QString & body) const
{
    QJsonObject notification;
    notification["tag"] = tag;
    notification["card"] = buildCard(origin, title, body);
    notification["sound"] = false;
    //notification["vibrate"] = vibrate();
    QJsonObject message;
    message["notification"] = notification;
    return message;
}

QJsonObject NotificationsProxy::buildCard(const QUrl & origin, const QString & title, const QString & body) const
{
    QJsonObject card;
    card["summary"] = title;
    card["body"] = body;
    card["popup"] = true;
    card["persist"] = true;

    QJsonArray actions = QJsonArray();
    QString actionUri = m_isWebApp ? QString("appid://%1/%2/current-user-version").arg(m_appId.split("_").at(0), m_appId.split("_").at(1)) : origin.toString();
    actions.append(actionUri);
    card["actions"] = actions;
    return card;
}
