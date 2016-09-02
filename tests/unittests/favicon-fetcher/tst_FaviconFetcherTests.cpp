/*
 * Copyright 2014-2016 Canonical Ltd.
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
#include <QtCore/QStringList>
#include <QtCore/QTextStream>
#include <QtNetwork/QTcpServer>
#include <QtNetwork/QTcpSocket>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "favicon-fetcher.h"

const unsigned char icon_data[] = {
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
    TestHTTPServer(QObject* parent = 0)
        : QTcpServer(parent)
    {
        connect(this, SIGNAL(newConnection()), SLOT(onNewConnection()));
    }

    QString baseURL() const
    {
        return "http://" + serverAddress().toString() + ":" + QString::number(serverPort());
    }

Q_SIGNALS:
    void gotRequest(const QString& path) const;
    void gotError() const;

private Q_SLOTS:
    void onNewConnection() {
        if (hasPendingConnections()) {
            QTcpSocket* socket = nextPendingConnection();
            connect(socket, SIGNAL(readyRead()), SLOT(readClient()));
            connect(socket, SIGNAL(disconnected()), SLOT(discardClient()));
            connect(socket, SIGNAL(error(QAbstractSocket::SocketError)), SIGNAL(gotError()));
        }
    }

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
        Q_EMIT gotRequest(path);
        QTextStream response(socket);
        response.setAutoDetectUnicode(true);
        QRegExp icon("/\\w+\\.ico");
        QRegExp redirection("^/redirect/(\\d+)/(.*)");
        if (icon.exactMatch(path)) {
            response << "HTTP/1.0 200 OK\r\n"
                     << "Content-Length: " << icon_data_size << "\r\n"
                     << "Content-Type: image/x-icon\r\n\r\n"
                     << QString::fromLocal8Bit((const char*) icon_data, icon_data_size) << "\n";
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
        } else {
            response << "HTTP/1.0 404 Not Found\r\n"
                     << "Content-Length: 9\r\n"
                     << "Content-Type: text/plain\r\n\r\n"
                     << "not found\n";
        }
        response.flush();
        socket->waitForBytesWritten();
        socket->disconnectFromHost();
    }

    void discardClient()
    {
        QTcpSocket* socket = qobject_cast<QTcpSocket*>(sender());
        if (socket) {
            socket->deleteLater();
        }
    }
};

class FaviconFetcherTests : public QObject
{
    Q_OBJECT

private:
    FaviconFetcher* fetcher;
    QSignalSpy* fetcherSpy;
    TestHTTPServer* server;
    QSignalSpy* serverSpy;
    QSignalSpy* errorSpy;

private Q_SLOTS:
    void init()
    {
        {
            FaviconFetcher temp;
            QDir(temp.cacheLocation()).removeRecursively();
        }
        fetcher = new FaviconFetcher;
        fetcherSpy = new QSignalSpy(fetcher, SIGNAL(localUrlChanged()));
        server = new TestHTTPServer;
        server->listen();
        serverSpy = new QSignalSpy(server, SIGNAL(gotRequest(const QString&)));
        errorSpy = new QSignalSpy(server, SIGNAL(gotError()));
    }

    void cleanup()
    {
        delete errorSpy;
        delete serverSpy;
        delete server;
        delete fetcherSpy;
        delete fetcher;
    }

    void shouldCacheIcon()
    {
        QUrl url(server->baseURL() + "/favicon1.ico");
        fetcher->setUrl(url);
        QCOMPARE(fetcher->url(), url);
        QVERIFY(fetcherSpy->wait());
        QCOMPARE(serverSpy->count(), 1);
        QString cached = fetcher->localUrl().path();
        QVERIFY(cached.startsWith(fetcher->cacheLocation()));
        QVERIFY(QFileInfo::exists(cached));
    }

    void shouldNotCacheLocalIcon()
    {
        QUrl url("file:///tmp/favicon.ico");
        fetcher->setUrl(url);
        QCOMPARE(fetcherSpy->count(), 1);
        QVERIFY(serverSpy->isEmpty());
        QCOMPARE(fetcher->localUrl(), url);
        QDir cache(fetcher->cacheLocation(), "", QDir::Unsorted, QDir::Files | QDir::NoDotAndDotDot);
        QCOMPARE(cache.count(), (uint) 0);
    }

    void shouldFailToDownloadInvalidIcon()
    {
        // First fetch a valid icon to ensure localUrl is initially not empty
        QUrl url(server->baseURL() + "/favicon1.ico");
        fetcher->setUrl(url);
        QVERIFY(fetcherSpy->wait());
        QVERIFY(!fetcher->localUrl().isEmpty());
        // Then request an invalid one
        url = QUrl(server->baseURL() + "/invalid.png");
        fetcher->setUrl(url);
        QVERIFY(serverSpy->wait());
        QVERIFY(fetcher->localUrl().isEmpty());
    }

    void shouldReturnCachedIcon()
    {
        // First fetch an icon so that it’s cached
        QUrl url(server->baseURL() + "/favicon1.ico");
        fetcher->setUrl(url);
        QVERIFY(fetcherSpy->wait());
        QUrl localUrl = fetcher->localUrl();
        QVERIFY(!localUrl.isEmpty());
        // Then fetch another icon
        fetcher->setUrl(QUrl(server->baseURL() + "/favicon2.ico"));
        QVERIFY(fetcherSpy->wait());
        QVERIFY(!fetcher->localUrl().isEmpty());
        // Then fetch the first icon again, and verify it comes from the cache
        serverSpy->clear();
        fetcher->setUrl(url);
        QCOMPARE(fetcher->localUrl(), localUrl);
        QVERIFY(serverSpy->isEmpty());
    }

    void shouldNotCacheIcon()
    {
        fetcher->setShouldCache(false);
        QUrl url(server->baseURL() + "/favicon1.ico");
        fetcher->setUrl(url);
        QCOMPARE(fetcher->url(), url);
        QVERIFY(fetcherSpy->wait());
        QCOMPARE(serverSpy->count(), 1);
        QUrl icon = fetcher->localUrl();
        QVERIFY(!icon.isLocalFile());
        QCOMPARE(icon.scheme(), QString("data"));
        QVERIFY(icon.path().startsWith("image/png;base64,"));
    }

    void shouldHandleRedirections()
    {
        QUrl url(server->baseURL() + "/redirect/3/favicon1.ico");
        fetcher->setUrl(url);
        QVERIFY(fetcherSpy->wait());
        QCOMPARE(serverSpy->count(), 4);
    }

    void shouldNotHandleTooManyRedirections()
    {
        QUrl url(server->baseURL() + "/redirect/8/favicon1.ico");
        QString msg("Failed to download %1 : too many redirections");
        QTest::ignoreMessage(QtWarningMsg, msg.arg(url.toString()).toUtf8());
        fetcher->setUrl(url);
        QVERIFY(!fetcherSpy->wait(500));
        QCOMPARE(serverSpy->count(), 5);
    }

    void shouldDiscardOldCachedIcons()
    {
        // First fetch an icon, and touch the cached file on disk to ensure
        // it will be considered out of date next time it’s requested
        QUrl url(server->baseURL() + "/favicon1.ico");
        fetcher->setUrl(url);
        QVERIFY(fetcherSpy->wait());
        QUrl localUrl = fetcher->localUrl();
        struct utimbuf ubuf;
        ubuf.modtime = QDateTime::currentDateTime().addYears(-1).toTime_t();
        QCOMPARE(utime(localUrl.path().toUtf8().constData(), &ubuf), 0);
        // Then fetch another icon
        fetcher->setUrl(QUrl(server->baseURL() + "/favicon2.ico"));
        QVERIFY(fetcherSpy->wait());
        QVERIFY(!fetcher->localUrl().isEmpty());
        // Then fetch the first icon again, and verify it is being re-downloaded
        serverSpy->clear();
        fetcher->setUrl(url);
        QVERIFY(fetcherSpy->wait());
        QCOMPARE(fetcher->localUrl(), localUrl);
        QCOMPARE(serverSpy->count(), 1);
    }

    void shouldCancelRequests()
    {
        // Issue several requests rapidly in succession, and verify that
        // all the previous ones are discarded. Take into account possible
        // errors (see https://launchpad.net/bugs/1498539).
        int requests = 100;
        int errors = 0;
        for (int i = 1; i <= requests; ++i) {
            QUrl url(server->baseURL() + "/favicon" + QString::number(i) + ".ico");
            fetcher->setUrl(url);
            QVERIFY(serverSpy->wait(500) || (errorSpy->count() == ++errors));
        }
        QVERIFY(fetcherSpy->wait());
        QVERIFY((serverSpy->count() + errorSpy->count()) >= requests);
        QCOMPARE(fetcherSpy->count(), 1);
    }
};

QTEST_MAIN(FaviconFetcherTests)

#include "tst_FaviconFetcherTests.moc"
