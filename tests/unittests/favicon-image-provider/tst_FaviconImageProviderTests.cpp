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

// system
#include <utime.h>

// Qt
#include <QtCore/QDateTime>
#include <QtCore/QDir>
#include <QtCore/QRegExp>
#include <QtCore/QString>
#include <QtCore/QTextStream>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QTcpServer>
#include <QtTest/QtTest>

// local
#include "favicon-image-provider.h"

const char icon_data[] = {
    0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x01, 0x02, 0x00, 0x01, 0x00,
    0x01, 0x00, 0x38, 0x00, 0x00, 0x00, 0x16, 0x00, 0x00, 0x00, 0x28, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x01, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
const int icon_data_size = 78;

class TestHTTPServer : public QTcpServer
{
    Q_OBJECT

public:
    QStringList requests;

    TestHTTPServer(QObject* parent = 0)
        : QTcpServer(parent)
    {}

    QString baseURL() const
    {
        return "http://" + serverAddress().toString() + ":" + QString::number(serverPort());
    }

protected:
    void incomingConnection(qintptr socketDescriptor)
    {
        QTcpSocket* socket = new QTcpSocket(this);
        connect(socket, SIGNAL(readyRead()), SLOT(readClient()));
        connect(socket, SIGNAL(disconnected()), SLOT(discardClient()));
        socket->setSocketDescriptor(socketDescriptor);
    }

private Q_SLOTS:
    void readClient()
    {
        QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
        if (!socket) {
            return;
        }
        if (!socket->canReadLine()) {
            return;
        }
        QStringList tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));
        if (tokens.isEmpty()) {
            return;
        }
        if (tokens.first() != "GET") {
            return;
        }
        QString path = tokens[1];
        requests << path;
        QTextStream response(socket);
        response.setAutoDetectUnicode(true);
        QRegExp icon("/\\w+\\.ico");
        QRegExp redirection("^/redirect/(\\d+)/(.*)");
        if (icon.exactMatch(path)) {
            response << "HTTP/1.0 200 OK\r\n"
                     << "Content-Length: " << icon_data_size << "\r\n"
                     << "Content-Type: image/x-icon\r\n\r\n"
                     << QString::fromLocal8Bit(icon_data, icon_data_size) << "\n";
        } else if (path == "/invalid") {
            response << "HTTP/1.0 404 Not Found\r\n"
                     << "Content-Length: 9\r\n"
                     << "Content-Type: text/plain\r\n\r\n"
                     << "not found\n";
        } else if (redirection.exactMatch(path)) {
            int n = redirection.cap(1).toInt();
            response << "HTTP/1.0 303 See Other\r\n"
                     << "Content-Length: 9\r\n"
                     << "Content-Type: text/plain\r\n"
                     << "Location: " << baseURL();
            if (n == 1) {
                response << "/" << redirection.cap(2);
            } else {
                response << "/redirect/" << (n - 1) << "/" << redirection.cap(2);
            }
            response << "\r\n\r\n"
                     << "see other\n";
        }
        socket->close();
    }

    void discardClient()
    {
        QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
        if (socket) {
            socket->deleteLater();
        }
    }
};

class FaviconImageProviderTests : public QObject
{
    Q_OBJECT

private:
    FaviconImageProvider* provider;
    TestHTTPServer* server;

private Q_SLOTS:
    void init()
    {
        {
            FaviconImageProvider temp;
            QDir(temp.cacheLocation()).removeRecursively();
        }
        provider = new FaviconImageProvider;
        server = new TestHTTPServer;
        server->listen();
    }

    void cleanup()
    {
        delete server;
        delete provider;
    }

    void shouldDiscardEmptyRequests()
    {
        QSize size;
        QImage icon = provider->requestImage("", &size, QSize());
        QVERIFY(icon.isNull());
        QVERIFY(!size.isValid());
    }

    void shouldFetchIcon()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/favicon1.ico", &size, QSize());
        QVERIFY(!icon.isNull());
        QCOMPARE(icon.size(), QSize(1, 1));
        QCOMPARE(size, QSize(1, 1));
        QCOMPARE(server->requests.size(), 1);
    }

    void shouldNotFetchInvalidIcon()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/invalid", &size, QSize());
        QVERIFY(icon.isNull());
        QVERIFY(!size.isValid());
        QCOMPARE(server->requests.size(), 1);
    }

    void shouldReturnCachedIcon()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/favicon2.ico", &size, QSize());
        QVERIFY(!icon.isNull());
        QCOMPARE(server->requests.size(), 1);
        server->requests.clear();
        QImage icon2 = provider->requestImage(server->baseURL() + "/favicon2.ico", &size, QSize());
        QVERIFY(!icon2.isNull());
        QVERIFY(server->requests.isEmpty());
    }

    void shouldHandleRedirections()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/redirect/3/favicon3.ico", &size, QSize());
        QVERIFY(!icon.isNull());
        QCOMPARE(icon.size(), QSize(1, 1));
        QCOMPARE(size, QSize(1, 1));
        QCOMPARE(server->requests.size(), 4);
    }

    void shouldNotHandleTooManyRedirections()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/redirect/8/favicon4.ico", &size, QSize());
        QVERIFY(icon.isNull());
        QVERIFY(!size.isValid());
        QCOMPARE(server->requests.size(), 5);
    }

    void shouldScaleIcon()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/favicon5.ico", &size, QSize(3, 3));
        QVERIFY(!icon.isNull());
        QCOMPARE(icon.size(), QSize(3, 3));
        QCOMPARE(size, QSize(1, 1));
    }

    void shouldDiscardOldCachedIcons()
    {
        QSize size;
        QImage icon = provider->requestImage(server->baseURL() + "/favicon6.ico", &size, QSize());
        QVERIFY(!icon.isNull());
        server->requests.clear();
        QDir cache(provider->cacheLocation(), "", QDir::Unsorted, QDir::Files | QDir::NoDotAndDotDot);
        QCOMPARE(cache.count(), (uint) 1);
        QString filepath = cache.filePath(cache[0]);
        struct utimbuf ubuf;
        ubuf.modtime = QDateTime::currentDateTime().addYears(-1).toTime_t();
        QCOMPARE(utime(filepath.toUtf8().constData(), &ubuf), 0);
        icon = provider->requestImage(server->baseURL() + "/favicon6.ico", &size, QSize());
        QVERIFY(!icon.isNull());
        QCOMPARE(server->requests.size(), 1);
    }
};

QTEST_MAIN(FaviconImageProviderTests)
#include "tst_FaviconImageProviderTests.moc"
