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
#include <QtCore/QDataStream>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QStandardPaths>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtNetwork/QLocalSocket>

#if defined(Q_OS_LINUX) || defined(Q_OS_UNIX)
#  include <sys/socket.h>
#  include <sys/un.h>
#endif

// local
#include "single-instance-manager.h"

namespace {

const int kWaitForRunningInstanceToRespondMs = 1000;
const int kWaitForRunningInstanceToAckMs = 1000;
const int kDataStreamVersion = QDataStream::Qt_5_0;
const QString kHeaderToken = QStringLiteral("MESSAGE");
const QString kAckToken = QStringLiteral("ACK");

/*
 *
 */
typedef QPair<QString, QString> ProfilePathParts;

ProfilePathParts getProfilePathPartsFromAppId(const QString& appId)
{
    QString profilePath =
            QStandardPaths::writableLocation(QStandardPaths::DataLocation);

    QStringList appIdParts = appId.split('_', QString::SkipEmptyParts);

    QString appDesktopName;

    // We try to get the "short app name" to try to uniquely identify
    // the single instance profile path.

    // In cases where you have a single click with multiple apps in it,
    // the "app name" as defined in the click manifest.json file will be
    // a proper way to distinguish a unique instance, it needs to take
    // the desktop name into account.

    // At the moment there is no clean way to get those click app name
    // paths, see:
    //  https://launchpad.net/bugs/1555542

    if (appIdParts.size() >= 3) {
        // Assume that we have a APP_ID that corresponds to:
        // <manifest app name>_<desktop app name>_<version>
        appDesktopName = appIdParts[1];
    } else {
        // We either run on desktop or as the webbrowser
        appDesktopName = appIdParts.first();
    }

    return ProfilePathParts(profilePath + QDir::separator(), appDesktopName);
}

bool ensureNameProfilePathExists(const QString& profilePath) {
    QDir profile(profilePath);
    if (!profile.exists()) {
        if (!QDir::root().mkpath(profile.absolutePath())) {
            qCritical() << "Failed to create profile directory,"
                           "unable to ensure a single instance of the application";
            return false;
        }
    }
    return true;
}

bool isValidLocalServerNameLength(const QString& serverName) {
#if defined(Q_OS_LINUX) || defined(Q_OS_UNIX)
    struct ::sockaddr_un addr;
    const QByteArray encodedServerName =
        QFile::encodeName(serverName);
    return (sizeof(addr.sun_path) >= (uint)encodedServerName.size() + 1);
#endif
    return true;
}

QString localServerNameFromProfilePath(const QString& profilePath) {
    return QDir(profilePath).absoluteFilePath(QStringLiteral("SingletonSocket"));
}

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

bool SingleInstanceManager::run(const QStringList& arguments, const QString& appId)
{
    if (m_server.isListening()) {
        return false;
    }

    ProfilePathParts parts =
            getProfilePathPartsFromAppId(appId);

    QString profilePath = parts.first + parts.second;

    QString serverName = localServerNameFromProfilePath(profilePath);

    // We cannot rely on QAbstractSocket::HostNotFoundError
    //
    // https://github.com/qt/qtbase/blob/dev/src/network/socket/qlocalserver_unix.cpp#L120
    //
    // to detect error caused by a server name that exceeds the limits (108 chars
    // as stated here http://man7.org/linux/man-pages/man7/unix.7.html for unix domain sockets)
    // A call to QLocalServer::listen() with too long of a name, does not cause errno to be set.
    // In this case, the return error ends up being UnknownError
    // https://github.com/qt/qtbase/blob/dev/src/network/socket/qlocalserver_unix.cpp#L310

    if (!isValidLocalServerNameLength(serverName)){
        profilePath = parts.first;

        qWarning() << "Could not create a local singleton name server with name"
                   << "'" << serverName << "'"
                   << ", which seems faulty.";

        serverName = localServerNameFromProfilePath(profilePath);

        qWarning() << "Trying with a shorter name"
                   << "'" << serverName << "', beware that it might cause some unintended"
                   << "behaviors in the application's cache management. To avoid that"
                   << "you could use a shorter application name.";
    }
    
    if (!ensureNameProfilePathExists(profilePath)) {
        return false;
    }

    if (listen(serverName)) {
        return true;
    }

    QLocalSocket socket;
    socket.connectToServer(serverName);
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
        if (QLocalServer::removeServer(serverName)) {
            if (listen(serverName)) {
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
