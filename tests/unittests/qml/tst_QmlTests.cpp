/*
 * Copyright 2013-2015 Canonical Ltd.
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

// Qt
#include <QtCore/QFile>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QTemporaryDir>
#include <QtQml/QtQml>
#include <QtQuickTest/QtQuickTest>

// local
#include "favicon-fetcher.h"
#include "file-operations.h"
#include "searchengine.h"

static QObject* FileOperations_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new FileOperations();
}

class TestContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString testDir1 READ testDir1 CONSTANT)
    Q_PROPERTY(QString testDir2 READ testDir2 CONSTANT)

public:
    explicit TestContext(QObject* parent=0)
        : QObject(parent)
    {}

    QString testDir1() const
    {
        return m_testDir1.path();
    }

    QString testDir2() const
    {
        return m_testDir2.path();
    }

    Q_INVOKABLE bool writeSearchEngineDescription(
        const QString& path, const QString& filename, const QString& name,
        const QString& description, const QString& urlTemplate)
    {
        QFile file(QDir(path).absoluteFilePath(QString("%1.xml").arg(filename)));
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&file);
            out << "<OpenSearchDescription xmlns=\"http://a9.com/-/spec/opensearch/1.1/\">";
            out << "<ShortName>" << name << "</ShortName>";
            out << "<Description>" << description << "</Description>";
            out << "<Url type=\"text/html\" template=\"" << urlTemplate << "\"/>";
            out << "</OpenSearchDescription>";
            file.close();
            return true;
        } else {
            return false;
        }
    }

    Q_INVOKABLE bool writeInvalidSearchEngineDescription(const QString& path, const QString& filename)
    {
        QFile file(QDir(path).absoluteFilePath(QString("%1.xml").arg(filename)));
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&file);
            out << "invalid";
            file.close();
            return true;
        } else {
            return false;
        }
    }

    Q_INVOKABLE bool deleteSearchEngineDescription(const QString& path, const QString& filename)
    {
        return QFile(QDir(path).absoluteFilePath(QString("%1.xml").arg(filename))).remove();
    }

private:
    QTemporaryDir m_testDir1;
    QTemporaryDir m_testDir2;
};

static QObject* TestContext_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new TestContext();
}

int main(int argc, char** argv)
{
    const char* commonUri = "webbrowsercommon.private";
    qmlRegisterType<FaviconFetcher>(commonUri, 0, 1, "FaviconFetcher");

    const char* browserUri = "webbrowserapp.private";
    qmlRegisterType<SearchEngine>(browserUri, 0, 1, "SearchEngine");
    qmlRegisterSingletonType<FileOperations>(browserUri, 0, 1, "FileOperations", FileOperations_singleton_factory);

    qmlRegisterSingletonType<TestContext>("webbrowsertest.private", 0, 1, "TestContext", TestContext_singleton_factory);

    return quick_test_main(argc, argv, "QmlTests", 0);
}

#include "tst_QmlTests.moc"
