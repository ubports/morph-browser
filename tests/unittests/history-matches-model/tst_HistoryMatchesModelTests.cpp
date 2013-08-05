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

// Qt
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "history-model.h"
#include "history-matches-model.h"


class HistoryMatchesModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* model;
    HistoryMatchesModel* matches;

private Q_SLOTS:
    void init()
    {
        model = new HistoryModel;
        model->setDatabasePath(":memory:");
        matches = new HistoryMatchesModel;
        matches->setSourceModel(model);
    }

    void cleanup()
    {
        delete matches;
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(matches->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(matches, SIGNAL(sourceModelChanged()));
        matches->setSourceModel(model);
        QVERIFY(spy.isEmpty());
        HistoryModel* model2 = new HistoryModel;
        matches->setSourceModel(model2);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(matches->sourceModel(), model2);
        matches->setSourceModel(0);
        QCOMPARE(spy.count(), 2);
        QCOMPARE(matches->sourceModel(), (HistoryModel*) 0);
        delete model2;
    }

    void shouldBeEmptyWhenQueryIsEmpty()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(matches->rowCount(), 0);
    }

    void shouldRecordQuery()
    {
        QVERIFY(matches->query().isEmpty());
        matches->setQuery("example");
        QCOMPARE(matches->query(), QString("example"));
    }

    void shouldMatchUrl()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        matches->setQuery("example");
        QCOMPARE(matches->rowCount(), 2);
    }

    void shouldMatchTitle()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        matches->setQuery("domain");
        QCOMPARE(matches->rowCount(), 2);
    }

    void shouldFilterOutNotMatchingEntries()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://ubuntu.com"), "Home | Ubuntu", QUrl());
        model->add(QUrl("http://example.com"), "Example Domain", QUrl());
        model->add(QUrl("http://wikipedia.org"), "Wikipedia", QUrl());
        matches->setQuery("example");
        QCOMPARE(matches->rowCount(), 2);
    }

    void shouldUpdateResultsWhenQueryChanges()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://ubuntu.com"), "Home | Ubuntu", QUrl());
        model->add(QUrl("http://wikipedia.org"), "Wikipedia", QUrl());
        model->add(QUrl("http://ubuntu.com/download"), "Download Ubuntu | Ubuntu", QUrl());
        matches->setQuery("ubuntu");
        QCOMPARE(matches->rowCount(), 2);
        matches->setQuery("wiki");
        QCOMPARE(matches->rowCount(), 1);
        matches->setQuery("");
        QCOMPARE(matches->rowCount(), 0);
    }

    void shouldUpdateResultsWhenHistoryChanges()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://wikipedia.org"), "Wikipedia", QUrl());
        matches->setQuery("ubuntu");
        QCOMPARE(matches->rowCount(), 0);
        model->add(QUrl("http://ubuntu.com"), "Home | Ubuntu", QUrl());
        QCOMPARE(matches->rowCount(), 1);
    }

    void shouldExtractTermsFromQuery()
    {
        matches->setQuery("ubuntu");
        QCOMPARE(matches->terms(), QStringList() << "ubuntu");
        matches->setQuery("download ubuntu");
        QCOMPARE(matches->terms(), QStringList() << "download" << "ubuntu");
        matches->setQuery("   ubuntu    touch  ");
        QCOMPARE(matches->terms(), QStringList() << "ubuntu" << "touch");
        matches->setQuery("ubuntu+touch");
        QCOMPARE(matches->terms(), QStringList() << "ubuntu+touch");
    }

    void shouldMatchAllTerms()
    {
        model->add(QUrl("http://example.org"), "Example Domain", QUrl());
        model->add(QUrl("http://ubuntu.com"), "Home | Ubuntu", QUrl());
        model->add(QUrl("http://wikipedia.org"), "Wikipedia", QUrl());
        model->add(QUrl("http://ubuntu.com/download"), "Download Ubuntu | Ubuntu", QUrl());
        matches->setQuery("ubuntu home");
        QCOMPARE(matches->rowCount(), 1);
        matches->setQuery("ubuntu wiki");
        QCOMPARE(matches->rowCount(), 0);
    }
};

QTEST_MAIN(HistoryMatchesModelTests)
#include "tst_HistoryMatchesModelTests.moc"
