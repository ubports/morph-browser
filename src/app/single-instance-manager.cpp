/*
 * Copyright 2016 Canonical Ltd.
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

// Implementation loosely based on Chromium’s ProcessSingleton
// (https://code.google.com/p/chromium/codesearch#chromium/src/chrome/browser/process_singleton_posix.cc).

// Qt
#include <QtCore/QByteArray>
#include <QtCore/QCoreApplication>
#include <QtCore/QDataStream>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtNetwork/QLocalSocket>

// local
#include "single-instance-manager.h"

namespace {
const int kWaitForRunningInstanceToRespondMs = 1000;
const int kWaitForRunningInstanceToAckMs = 1000;
const int kDataStreamVersion = QDataStream::Qt_5_0;
const QString kHeaderToken = QStringLiteral("MESSAGE");
const QString kAckToken = QStringLiteral("ACK");
}

// static
QString SingleInstanceManager::getProfilePath()
{
    QString profilePath =
            QStandardPaths::writableLocation(QStandardPaths::DataLocation);

    // Take the app_name into account when creating the
    QStringList appIdParts =
            QString::fromUtf8(qgetenv("APP_ID")).split
                ('_', QString::SkipEmptyParts);

    if (appIdParts.isEmpty()) {
        // Should not happen
        return profilePath;
    }

    QString appDesktopName;

    // We try to guess the
    // https://bugs.launchpad.net/ubuntu/+source/ubuntu-ui-toolkit/+bug/1555542
    if (appIdParts.size() >= 3) {
        // Assume that we have a APP_ID that corresponds to:
        // <manifest app name>_<desktop app name>_<version>
        appDesktopName = QStringList(appIdParts.mid(0, 2)).join('_');
    } else {
        // We either run on desktop or as the webbrowser
        appDesktopName = appIdParts.first();
    }

    qDebug() << appIdParts << appDesktopName;
    qDebug() << appIdParts.size();

    return profilePath
        + QDir::separator()
        + appDesktopName;
}

SingleInstanceManager::SingleInstanceManager(QObject* parent)
    : QObject(parent)
{}

bool SingleInstanceManager::listen(const QString& name)
{
    if (m_server.listen(name)) {
        connect(&m_server, SIGNAL(newConnection()),
                SLOT(onNewInstanceConnected()));
        return true;
    }
    return false;
}

bool SingleInstanceManager::run(const QStringList& arguments)
{
    if (m_server.isListening()) {
        return false;
    }

    QDir profile(getProfilePath());
    if (!profile.exists()) {
        if (!QDir::root().mkpath(profile.absolutePath())) {
            qCritical() << "Failed to create profile directory,"
                           "unable to ensure a single instance of the application";
            return false;
        }
    }
    QString name = profile.absoluteFilePath(QStringLiteral("SingletonSocket"));
    // XXX: Unix domain sockets limit the length of the pathname to 108 characters.
    //  We should probably handle QAbstractSocket::HostNotFoundError explicitly.

    if (listen(name)) {
        return true;
    }

    QLocalSocket socket;
    socket.connectToServer(name);
    if (socket.waitForConnected(kWaitForRunningInstanceToRespondMs)) {
        qWarning() << "Passing arguments to already running instance";
        QByteArray block;
        QDataStream message(&block, QIODevice::WriteOnly);
        message.setVersion(kDataStreamVersion);
        message << kHeaderToken;
        Q_FOREACH(const QString& argument, arguments) {
            message << argument;
        }
        socket.write(block);
        socket.waitForBytesWritten();

        if (socket.waitForReadyRead(kWaitForRunningInstanceToAckMs)) {
            block = socket.readAll();
            QDataStream response(&block, QIODevice::ReadOnly);
            response.setVersion(kDataStreamVersion);
            QString ack;
            response >> ack;
            if (ack != kAckToken) {
                qCritical() << "Received malformed ack from already running instance";
            }
        } else {
            qCritical() << "Already running instance did not acknowledge message reception";
        }
        socket.disconnectFromServer();
    } else {
        // Failed to talk to already running instance, assume it crashed.
        if (QLocalServer::removeServer(name)) {
            if (listen(name)) {
                return true;
            } else {
                qCritical() << "Failed to launch single instance:"
                            << m_server.errorString();
            }
        } else {
            qCritical() << "Failed to recover from a previous crash";
        }
    }

    return false;
}

void SingleInstanceManager::onNewInstanceConnected()
{
    if (m_server.hasPendingConnections()) {
        QLocalSocket* socket = m_server.nextPendingConnection();
        connect(socket, SIGNAL(readyRead()), SLOT(onReadyRead()));
        connect(socket, SIGNAL(disconnected()), SLOT(onDisconnected()));
    }
}

void SingleInstanceManager::onReadyRead()
{
    QLocalSocket* socket = qobject_cast<QLocalSocket*>(sender());
    if (!socket) {
        return;
    }

    QByteArray block = socket->readAll();
    QDataStream message(&block, QIODevice::ReadOnly);
    message.setVersion(kDataStreamVersion);
    QStringList arguments;
    while (!message.atEnd()) {
        QString token;
        message >> token;
        arguments << token;
    }
    if (arguments.takeFirst() != kHeaderToken) {
        qCritical() << "Received a malformed message from another instance";
        return;
    }
    Q_EMIT newInstanceLaunched(arguments);

    // Send ack to new instance
    block.clear();
    QDataStream ack(&block, QIODevice::WriteOnly);
    ack.setVersion(kDataStreamVersion);
    ack << kAckToken;
    socket->write(block);
    socket->flush();
}

void SingleInstanceManager::onDisconnected()
{
    QLocalSocket* socket = qobject_cast<QLocalSocket*>(sender());
    if (socket) {
        socket->deleteLater();
    }
}
