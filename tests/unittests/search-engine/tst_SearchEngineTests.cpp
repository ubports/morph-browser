/*
 * Copyright 2015 Canonical Ltd.
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
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QTemporaryDir>
#include <QtCore/QTextStream>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "searchengine.h"

class SearchEngineTests : public QObject
{
    Q_OBJECT

private:
    QTemporaryDir* dir1;
    QTemporaryDir* dir2;
    SearchEngine* engine;
    QSignalSpy* searchPathsSpy;
    QSignalSpy* filenameSpy;
    QSignalSpy* nameSpy;
    QSignalSpy* descriptionSpy;
    QSignalSpy* urlTemplateSpy;
    QSignalSpy* suggestionsUrlTemplateSpy;
    QSignalSpy* validSpy;

private Q_SLOTS:
    void init()
    {
        dir1 = new QTemporaryDir;
        QVERIFY(dir1->isValid());

        dir2 = new QTemporaryDir;
        QVERIFY(dir2->isValid());

        engine = new SearchEngine;
        searchPathsSpy = new QSignalSpy(engine, SIGNAL(searchPathsChanged()));
        filenameSpy = new QSignalSpy(engine, SIGNAL(filenameChanged()));
        nameSpy = new QSignalSpy(engine, SIGNAL(nameChanged()));
        descriptionSpy = new QSignalSpy(engine, SIGNAL(descriptionChanged()));
        urlTemplateSpy = new QSignalSpy(engine, SIGNAL(urlTemplateChanged()));
        suggestionsUrlTemplateSpy = new QSignalSpy(engine, SIGNAL(suggestionsUrlTemplateChanged()));
        validSpy = new QSignalSpy(engine, SIGNAL(validChanged()));

        QFile file(QDir(dir1->path()).absoluteFilePath("engine1.xml"));
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        QTextStream out(&file);
        out << "<OpenSearchDescription xmlns=\"http://a9.com/-/spec/opensearch/1.1/\">";
        out << "<ShortName>engine1</ShortName>";
        out << "<Description>engine1 search</Description>";
        out << "<Url type=\"text/html\" template=\"https://example.org/search1?q={searchTerms}\"/>";
        out << "<Url type=\"application/x-suggestions+json\" template=\"https://example.org/suggest1?q={searchTerms}\"/>";
        out << "</OpenSearchDescription>";
        file.close();

        file.setFileName(QDir(dir2->path()).absoluteFilePath("engine2.xml"));
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        out.setDevice(&file);
        out << "<OpenSearchDescription xmlns=\"http://a9.com/-/spec/opensearch/1.1/\">";
        out << "<ShortName>engine2</ShortName>";
        out << "<Url type=\"text/html\" template=\"https://example.org/search2?q={searchTerms}\"/>";
        out << "</OpenSearchDescription>";
        file.close();

        file.setFileName(QDir(dir2->path()).absoluteFilePath("invalid.xml"));
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        out.setDevice(&file);
        out << "invalid";
        file.close();

        engine->setSearchPaths({dir1->path(), dir2->path()});
        QCOMPARE(searchPathsSpy->count(), 1);
        searchPathsSpy->clear();
        nameSpy->clear();
        descriptionSpy->clear();
        urlTemplateSpy->clear();
        suggestionsUrlTemplateSpy->clear();
        validSpy->clear();
        QVERIFY(!engine->isValid());
    }

    void cleanup()
    {
        delete validSpy;
        delete suggestionsUrlTemplateSpy;
        delete urlTemplateSpy;
        delete descriptionSpy;
        delete nameSpy;
        delete filenameSpy;
        delete searchPathsSpy;
        delete engine;
        delete dir1;
        delete dir2;
    }

    void shouldChangeSearchPaths()
    {
        QCOMPARE(engine->searchPaths(), QStringList({dir1->path(), dir2->path()}));
        engine->setSearchPaths({dir2->path()});
        QCOMPARE(searchPathsSpy->count(), 1);
        QCOMPARE(engine->searchPaths(), QStringList({dir2->path()}));
    }

    void shouldChangeFilename()
    {
        QVERIFY(engine->filename().isEmpty());
        engine->setFilename("engine1");
        QCOMPARE(filenameSpy->count(), 1);
        QCOMPARE(engine->filename(), QString("engine1"));
        engine->setFilename("");
        QCOMPARE(filenameSpy->count(), 2);
        QVERIFY(engine->filename().isEmpty());
    }

    void shouldParseValidDescriptionWithDescription()
    {
        engine->setFilename("engine1");
        QCOMPARE(nameSpy->count(), 1);
        QCOMPARE(engine->name(), QString("engine1"));
        QCOMPARE(descriptionSpy->count(), 1);
        QCOMPARE(engine->description(), QString("engine1 search"));
        QCOMPARE(urlTemplateSpy->count(), 1);
        QCOMPARE(engine->urlTemplate(), QString("https://example.org/search1?q={searchTerms}"));
        QCOMPARE(suggestionsUrlTemplateSpy->count(), 1);
        QCOMPARE(engine->suggestionsUrlTemplate(), QString("https://example.org/suggest1?q={searchTerms}"));
        QCOMPARE(validSpy->count(), 1);
        QVERIFY(engine->isValid());
    }

    void shouldParseValidDescriptionWithoutDescriptionAndSuggestionsTemplate()
    {
        engine->setFilename("engine2");
        QCOMPARE(nameSpy->count(), 1);
        QCOMPARE(engine->name(), QString("engine2"));
        QVERIFY(descriptionSpy->isEmpty());
        QVERIFY(engine->description().isEmpty());
        QCOMPARE(urlTemplateSpy->count(), 1);
        QCOMPARE(engine->urlTemplate(), QString("https://example.org/search2?q={searchTerms}"));
        QVERIFY(suggestionsUrlTemplateSpy->isEmpty());
        QVERIFY(engine->suggestionsUrlTemplate().isEmpty());
        QCOMPARE(validSpy->count(), 1);
        QVERIFY(engine->isValid());
    }

    void shouldFailToParseInvalidDescription()
    {
        engine->setFilename("invalid");
        QVERIFY(nameSpy->isEmpty());
        QVERIFY(engine->name().isEmpty());
        QVERIFY(descriptionSpy->isEmpty());
        QVERIFY(engine->description().isEmpty());
        QVERIFY(urlTemplateSpy->isEmpty());
        QVERIFY(engine->urlTemplate().isEmpty());
        QVERIFY(suggestionsUrlTemplateSpy->isEmpty());
        QVERIFY(engine->suggestionsUrlTemplate().isEmpty());
        QVERIFY(validSpy->isEmpty());
        QVERIFY(!engine->isValid());
    }

    void shouldFailToLocateNonexistentDescription()
    {
        engine->setFilename("nonexistent");
        QVERIFY(nameSpy->isEmpty());
        QVERIFY(engine->name().isEmpty());
        QVERIFY(descriptionSpy->isEmpty());
        QVERIFY(engine->description().isEmpty());
        QVERIFY(urlTemplateSpy->isEmpty());
        QVERIFY(engine->urlTemplate().isEmpty());
        QVERIFY(suggestionsUrlTemplateSpy->isEmpty());
        QVERIFY(engine->suggestionsUrlTemplate().isEmpty());
        QVERIFY(validSpy->isEmpty());
        QVERIFY(!engine->isValid());
    }

    void shouldOverrideExistingDescription()
    {
        QFile file(QDir(dir1->path()).absoluteFilePath("engine2.xml"));
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        QTextStream out(&file);
        out << "<OpenSearchDescription xmlns=\"http://a9.com/-/spec/opensearch/1.1/\">";
        out << "<ShortName>engine2-overridden</ShortName>";
        out << "<Description>engine2 overridden search</Description>";
        out << "<Url type=\"text/html\" template=\"https://example.org/search2overridden?q={searchTerms}\"/>";
        out << "<Url type=\"application/x-suggestions+json\" template=\"https://example.org/suggest2?q={searchTerms}\"/>";
        out << "</OpenSearchDescription>";
        file.close();

        engine->setFilename("engine2");
        QCOMPARE(nameSpy->count(), 1);
        QCOMPARE(engine->name(), QString("engine2-overridden"));
        QCOMPARE(descriptionSpy->count(), 1);
        QCOMPARE(engine->description(), QString("engine2 overridden search"));
        QCOMPARE(urlTemplateSpy->count(), 1);
        QCOMPARE(engine->urlTemplate(), QString("https://example.org/search2overridden?q={searchTerms}"));
        QCOMPARE(suggestionsUrlTemplateSpy->count(), 1);
        QCOMPARE(engine->suggestionsUrlTemplate(), QString("https://example.org/suggest2?q={searchTerms}"));
        QCOMPARE(validSpy->count(), 1);
        QVERIFY(engine->isValid());
    }

    void shouldOverrideAndInvalidateDescription()
    {
        QFile file(QDir(dir1->path()).absoluteFilePath("engine2.xml"));
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.close();

        engine->setFilename("engine2");
        QVERIFY(nameSpy->isEmpty());
        QVERIFY(engine->name().isEmpty());
        QVERIFY(descriptionSpy->isEmpty());
        QVERIFY(engine->description().isEmpty());
        QVERIFY(urlTemplateSpy->isEmpty());
        QVERIFY(engine->urlTemplate().isEmpty());
        QVERIFY(suggestionsUrlTemplateSpy->isEmpty());
        QVERIFY(engine->suggestionsUrlTemplate().isEmpty());
        QVERIFY(validSpy->isEmpty());
        QVERIFY(!engine->isValid());
    }
};

QTEST_MAIN(SearchEngineTests)

#include "tst_SearchEngineTests.moc"
