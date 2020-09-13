/* Copyright (C) 2017 Dan Chapman <dpniel@ubuntu.com> (used pushclient.cpp of dekko as base)
 * Copyright 2020 UBports Foundation
 *
 * This file is part of morph-browser
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
#include "pushclient.h"
#include <QPointer>
#include <QByteArray>
#include <QtDBus/QDBusMessage>
#include <QJsonDocument>
#include <QDebug>

#define POSTAL_SERVICE "com.ubuntu.Postal"
#define POSTAL_PATH "/com/ubuntu/Postal"
#define POSTAL_IFACE "com.ubuntu.Postal"

static QPointer<PushClient> s_client;
PushClient *PushClient::instance()
{
    if (s_client.isNull()) {
        s_client = new PushClient();
    }
    return s_client;
}

PushClient::PushClient(QObject *parent) : QObject(parent),
    m_conn(QDBusConnection::sessionBus())
{
}

void PushClient::setAppId(const QString & appId)
{
    m_appId = appId;
    m_tags = getPersistent();
    updateCount();
}

//shamelessly stolen from accounts-polld
bool PushClient::send(const QJsonObject &message)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                      makePath(),
                                                      POSTAL_IFACE,
                                                      "Post");
    msg << m_appId;
    QByteArray data = QJsonDocument(message).toJson(QJsonDocument::Compact);
    msg << QString::fromUtf8(data);

    qDebug() << "[POST] >>  " << msg;

    QDBusMessage reply = m_conn.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << "[POST ERROR] " << reply.errorMessage();
        return false;
    }
    qDebug() << "[POST SUCCESS] >> Message posted.";
    QJsonObject n = message.value("notification").toObject();
    QString tag = n.value("tag").toString();
    updateCount(tag);
    return true;
}

bool PushClient::update(const QString &tag, const QJsonObject &message)
{
    if (hasTag(tag)) {
        clearPersistent(tag);
    }
    return send(message);
}

bool PushClient::hasTag(const QString &tag)
{
    return m_tags.contains(tag);
}

bool PushClient::clearPersistent(const QString &tag)
{
    if (m_tags.contains(tag)) {
        qDebug() << "[REMOVE] >> Removing message: " << tag;
        QDBusMessage message = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                              makePath(),
                                                              POSTAL_IFACE,
                                                              "ClearPersistent");
        message << m_appId;
        message << tag;

        QDBusMessage reply = m_conn.call(message);
        if (reply.type() == QDBusMessage::ErrorMessage) {
            qDebug() << "[REMOVE ERROR] " << reply.errorMessage();
            return false;
        }
        qDebug() << "[REMOVE SUCCESS] Notification removed";
        return updateCount(tag, true);
    }
    return false;
}

bool PushClient::updateCount(const QString &tag, const bool remove)
{
    qDebug() << "[COUNT] >> Updating launcher count";
    if (!tag.isEmpty()) {
        if (!remove && !m_tags.contains(tag)) {
            qDebug() << "[COUNT] >> Tag not yet in persistent list. adding it now: " << tag;
            m_tags << tag;
        }

        if (remove && m_tags.contains(tag)) {
            qDebug() << "[COUNT] >> Removing tag from persistent list: " << tag;
            m_tags.removeAll(tag);
        }
    }

    bool visible = m_tags.count() != 0;
    QDBusMessage message = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                          makePath(),
                                                          POSTAL_IFACE,
                                                          "SetCounter");
    message << m_appId << m_tags.count() << visible;
    bool result = m_conn.send(message);
    if (result) {
        qDebug() << "[COUNT] >> Updated.";
    }
    return result;
}

//shamelessly stolen from accounts-polld
QByteArray PushClient::makePath()
{
    QByteArray path(QByteArrayLiteral("/com/ubuntu/Postal/"));

    QByteArray pkg = m_appId.split('_').first().toUtf8();
    
    // legacy apps have _ as path
    if (pkg.count() == 0) {
       path += '_';
    }

    // path for click apps
    for (int i = 0; i < pkg.count(); i++) {
        char buffer[10];
        char c = pkg[i];
        switch (c) {
        case '+':
        case '.':
        case '-':
        case ':':
        case '~':
        case '_':
            sprintf(buffer, "_%.2x", c);
            path += buffer;
            break;
        default:
            path += c;
        }
    }
    qDebug() << "[PATH] >> " << path;
    return path;
}

QStringList PushClient::getPersistent()
{
    QDBusMessage message = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                          makePath(),
                                                          POSTAL_IFACE,
                                                          "ListPersistent");
    message << m_appId;
    QDBusMessage reply = m_conn.call(message);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << reply.errorMessage();
        return QStringList();
    }
    QStringList tags = reply.arguments()[0].toStringList();
    qDebug() << "[TAGS] >> " << tags;
    return tags;
}
