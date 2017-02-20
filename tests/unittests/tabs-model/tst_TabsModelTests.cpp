/*
 * Copyright 2013-2017 Canonical Ltd.
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
#include <QtCore/QStringList>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlProperty>
#include <QtQuick/QQuickItem>
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "tabs-model.h"

class TabsModelTests : public QObject
{
    Q_OBJECT

private:
    QQmlEngine engine;
    TabsModel* model;

    QQuickItem* createTab()
    {
        QQmlComponent component(&engine);
        QByteArray data("import QtQuick 2.4\nItem {\nproperty url url\n"
                        "property string title\nproperty url icon\n}");
        component.setData(data, QUrl());
        QObject* object = component.create();
        object->setParent(this);
        QQuickItem* item = qobject_cast<QQuickItem*>(object);
        return item;
    }

    QQuickItem* createTabWithTitle(const QString& title) {
        QQuickItem* tab = createTab();
        tab->setProperty("title", title);
        return tab;
    }

    void verifyTabsOrder(QStringList orderedTitles) {
        QCOMPARE(model->rowCount(), orderedTitles.count());
        int i = 0;
        Q_FOREACH(QString title, orderedTitles) {
            QCOMPARE(model->get(i++)->property("title").toString(), title);
        }
    }

private Q_SLOTS:
    void init()
    {
        model = new TabsModel;
    }

    void cleanup()
    {
        while (model->rowCount() > 0) {
            delete model->remove(0);
        }
        delete model;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(model->currentTab(), (QObject*) nullptr);
    }

    void shouldExposeRoleNames()
    {
        QList<QByteArray> roleNames = model->roleNames().values();
        QVERIFY(roleNames.contains("url"));
        QVERIFY(roleNames.contains("title"));
        QVERIFY(roleNames.contains("icon"));
        QVERIFY(roleNames.contains("tab"));
    }

    void shouldNotAllowSettingTheIndexToAnInvalidValue_data()
    {
        QTest::addColumn<int>("index");
        QTest::newRow("zero") << 0;
        QTest::newRow("too high") << 2;
        QTest::newRow("too low") << -2;
    }

    void shouldNotAllowSettingTheIndexToAnInvalidValue()
    {
        QFETCH(int, index);
        model->setCurrentIndex(index);
        QCOMPARE(model->currentIndex(), -1);
        QCOMPARE(model->currentTab(), (QObject*) nullptr);
    }

    void shouldNotAddNullTab()
    {
        QCOMPARE(model->add(0), -1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldReturnIndexWhenAddingTab()
    {
        for(int i = 0; i < 3; ++i) {
            QCOMPARE(model->add(createTab()), i);
        }
    }

    void shouldUpdateCountWhenAddingTab()
    {
        QSignalSpy spy(model, SIGNAL(countChanged()));
        model->add(createTab());
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldNotInsertNullTab()
    {
        QCOMPARE(model->insert(0, 0), -1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldReturnIndexWhenInsertingTab()
    {
        for(int i = 0; i < 3; ++i) {
            model->add(createTab());
        }
        for(int i = 2; i >= 0; --i) {
            QCOMPARE(model->insert(createTab(), i), i);
        }
    }

    void shouldUpdateCountWhenInsertingTab()
    {
        QSignalSpy spy(model, SIGNAL(countChanged()));
        model->insert(createTab(), 0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 1);
    }

    void shouldInsertAtCorrectIndex()
    {
        model->insert(createTabWithTitle("B"), 0);
        model->insert(createTabWithTitle("A"), 0);
        verifyTabsOrder(QStringList({"A", "B"}));
        model->insert(createTabWithTitle("X"), 1);
        verifyTabsOrder(QStringList({"A", "X", "B"}));
        model->insert(createTabWithTitle("C"), 3);
        verifyTabsOrder(QStringList({"A", "X", "B", "C"}));
    }

    void shouldClampIndexWhenInsertingTabOutOfBounds()
    {
        model->add(createTabWithTitle("A"));
        model->add(createTabWithTitle("B"));
        model->insert(createTabWithTitle("C"), 3);
        verifyTabsOrder(QStringList({"A", "B", "C"}));
        model->insert(createTabWithTitle("X"), -1);
        verifyTabsOrder(QStringList({"X", "A", "B", "C"}));
    }

    void shouldUpdateCountWhenRemovingTab()
    {
        model->add(createTab());
        QSignalSpy spy(model, SIGNAL(countChanged()));
        delete model->remove(0);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotAllowRemovingAtInvalidIndex()
    {
        QCOMPARE(model->remove(0), (QObject*) nullptr);
        QCOMPARE(model->remove(2), (QObject*) nullptr);
        QCOMPARE(model->remove(-2), (QObject*) nullptr);
    }

    void shouldReturnTabWhenRemoving()
    {
        QQuickItem* tab = createTab();
        model->add(tab);
        QObject* removed = model->remove(0);
        QCOMPARE(removed, tab);
        delete removed;
    }

    void shouldNotDeleteTabWhenRemoving()
    {
        QQuickItem* tab = createTab();
        model->add(tab);
        model->remove(0);
        QCOMPARE(tab->parent(), this);
        delete tab;
    }

    void shouldNotifyWhenAddingTab()
    {
        QSignalSpy spy(model, SIGNAL(rowsInserted(const QModelIndex&, int, int)));
        for(int i = 0; i < 3; ++i) {
            model->add(createTab());
            QCOMPARE(spy.count(), 1);
            QList<QVariant> args = spy.takeFirst();
            QCOMPARE(args.at(1).toInt(), i);
            QCOMPARE(args.at(2).toInt(), i);
        }
    }

    void shouldNotifyWhenRemovingTab()
    {
        QSignalSpy spy(model, SIGNAL(rowsRemoved(const QModelIndex&, int, int)));
        for(int i = 0; i < 5; ++i) {
            model->add(createTab());
        }
        delete model->remove(3);
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(1).toInt(), 3);
        QCOMPARE(args.at(2).toInt(), 3);
        for(int i = 3; i >= 0; --i) {
            delete model->remove(i);
            QCOMPARE(spy.count(), 1);
            args = spy.takeFirst();
            QCOMPARE(args.at(1).toInt(), i);
            QCOMPARE(args.at(2).toInt(), i);
        }
    }

    void shouldNotifyWhenTabPropertiesChange()
    {
        qRegisterMetaType<QVector<int> >();
        QSignalSpy spy(model, SIGNAL(dataChanged(const QModelIndex&, const QModelIndex&, const QVector<int>&)));
        QQuickItem* tab = createTab();
        model->add(tab);

        QQmlProperty(tab, "url").write(QUrl("http://ubuntu.com"));
        QCOMPARE(spy.count(), 1);
        QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        QVector<int> roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Url));

        QQmlProperty(tab, "title").write(QString("Lorem Ipsum"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Title));

        QQmlProperty(tab, "icon").write(QUrl("image://webicon/123"));
        QCOMPARE(spy.count(), 1);
        args = spy.takeFirst();
        QCOMPARE(args.at(0).toModelIndex().row(), 0);
        QCOMPARE(args.at(1).toModelIndex().row(), 0);
        roles = args.at(2).value<QVector<int> >();
        QCOMPARE(roles.size(), 1);
        QVERIFY(roles.contains(TabsModel::Icon));
    }

    void shouldUpdateCurrentTabWhenSettingCurrentIndex()
    {
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        QSignalSpy spy(model, SIGNAL(currentTabChanged()));
        model->setCurrentIndex(0);
        QCOMPARE(model->currentIndex(), 0);
        QVERIFY(spy.isEmpty());
        QCOMPARE(model->currentTab(), tab1);
        QQuickItem* tab2 = createTab();
        model->add(tab2);
        model->setCurrentIndex(1);
        QCOMPARE(model->currentIndex(), 1);
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->currentTab(), tab2);
    }

    void shouldSetCurrentTabWhenAddingFirstTab()
    {
        // Adding a tab to an empty model should update the current tab
        // to that tab
        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        QCOMPARE(model->currentIndex(), -1);
        QCOMPARE(model->currentTab(), (QObject*) nullptr);

        QQuickItem* tab1 = createTab();
        model->add(tab1);

        QCOMPARE(spytab.count(), 1);
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentIndex(), 0);
        QCOMPARE(model->currentTab(), tab1);

        // But adding further items should keep the index where it was
        model->add(createTab());
        model->add(createTab());

        QCOMPARE(spytab.count(), 1);
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentIndex(), 0);
        QCOMPARE(model->currentTab(), tab1);
    }

    void shouldSetCurrentTabWhenInsertingFirstTab()
    {
        // Inserting a tab to an empty model should update the current tab
        // to that tab
        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        QCOMPARE(model->currentIndex(), -1);
        QCOMPARE(model->currentTab(), (QObject*) nullptr);

        QQuickItem* tab1 = createTab();
        model->insert(tab1, 0);

        QCOMPARE(spytab.count(), 1);
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentIndex(), 0);
        QCOMPARE(model->currentTab(), tab1);
    }

    void shouldUpdateCurrentTabWhenInsertingAtCurrentIndex()
    {
        QQuickItem* tab1 = createTab();
        model->insert(tab1, 0);
        QCOMPARE(model->currentIndex(), 0);
        QCOMPARE(model->currentTab(), tab1);

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));

        QQuickItem* tab2 = createTab();
        model->insert(tab2, 0);

        QVERIFY(spyindex.isEmpty());
        QCOMPARE(spytab.count(), 1);
        QCOMPARE(model->currentTab(), tab2);
    }

    void shouldUpdateCurrentIndexWhenInsertingBeforeCurrentIndex()
    {
        model->insert(createTab(), 0);
        model->insert(createTab(), 0);
        model->setCurrentIndex(1);
        QObject* current = model->currentTab();

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));

        model->insert(createTab(), 0);

        QVERIFY(spytab.isEmpty());
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentTab(), current);
        QCOMPARE(model->currentIndex(), 2);
    }

    void shouldSetInvalidIndexWhenRemovingLastTab()
    {
        // Removing the last item should also set the current index to -1
        // and the current tab to null
        model->add(createTab());

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        delete model->remove(0);
        QCOMPARE(spytab.count(), 1);
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentIndex(), -1);
        QCOMPARE(model->currentTab(), (QObject*) nullptr);
    }

    void shouldNotChangeIndexWhenRemovingAfterCurrent()
    {
        // When removing a tab after the current one,
        // the current tab shouldn’t change.
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        model->add(createTab());

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        delete model->remove(1);
        QCOMPARE(model->currentTab(), tab1);
        QVERIFY(spytab.isEmpty());
        QVERIFY(spyindex.isEmpty());
    }

    void shouldUpdateIndexWhenRemovingCurrent()
    {
        // When removing the current tab, if there is a tab after it,
        // it becomes the current one.
        QQuickItem* tab1 = createTab();
        QQuickItem* tab2 = createTab();
        QQuickItem* tab3 = createTab();
        model->add(tab1);
        model->add(tab2);
        model->add(tab3);
        model->setCurrentIndex(1);
        QCOMPARE(model->currentIndex(), 1);
        QCOMPARE(model->currentTab(), tab2);

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        delete model->remove(1);
        QCOMPARE(spyindex.count(), 0);
        QCOMPARE(spytab.count(), 1);
        QCOMPARE(model->currentTab(), tab3);

        // If there is no tab after it but one before, that one becomes current
        delete model->remove(1);
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(spytab.count(), 2);
        QCOMPARE(model->currentIndex(), 0);
        QCOMPARE(model->currentTab(), tab1);
    }

    void shouldDecreaseIndexWhenRemovingBeforeCurrent()
    {
        // When removing a tab before the current tab, the current index
        // should decrease to match.
        model->add(createTab());
        model->add(createTab());
        QQuickItem* tab = createTab();
        model->add(tab);
        model->setCurrentIndex(2);

        QSignalSpy spytab(model, SIGNAL(currentTabChanged()));
        QSignalSpy spyindex(model, SIGNAL(currentIndexChanged()));
        delete model->remove(1);
        QVERIFY(spytab.isEmpty());
        QCOMPARE(spyindex.count(), 1);
        QCOMPARE(model->currentIndex(), 1);
        QCOMPARE(model->currentTab(), tab);
    }

    void shouldReturnData()
    {
        QQuickItem* tab = createTab();
        QQmlProperty(tab, "url").write(QUrl("http://ubuntu.com/"));
        QQmlProperty(tab, "title").write(QString("Lorem Ipsum"));
        QQmlProperty(tab, "icon").write(QUrl("image://webicon/123"));
        model->add(tab);
        QVERIFY(!model->data(QModelIndex(), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(-1, 0), TabsModel::Url).isValid());
        QVERIFY(!model->data(model->index(3, 0), TabsModel::Url).isValid());
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Url).toUrl(), QUrl("http://ubuntu.com/"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Title).toString(), QString("Lorem Ipsum"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Icon).toUrl(), QUrl("image://webicon/123"));
        QCOMPARE(model->data(model->index(0, 0), TabsModel::Tab).value<QQuickItem*>(), tab);
        QVERIFY(!model->data(model->index(0, 0), TabsModel::Tab + 3).isValid());
    }

    void shouldReturnTabAtIndex()
    {
        // valid indexes
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        QQuickItem* tab2 = createTab();
        model->add(tab2);
        QQuickItem* tab3 = createTab();
        model->add(tab3);
        QCOMPARE(model->get(0), tab1);
        QCOMPARE(model->get(1), tab2);
        QCOMPARE(model->get(2), tab3);

        // invalid indexes
        QCOMPARE(model->get(-1), (QObject*) nullptr);
        QCOMPARE(model->get(3), (QObject*) nullptr);
    }

    void shouldReturnTabIndex()
    {
        QQuickItem* tab1 = createTab();
        model->add(tab1);
        QQuickItem* tab2 = createTab();
        model->add(tab2);
        QQuickItem* nonAddedTab = createTab();
        QCOMPARE(model->indexOf(tab1), 0);
        QCOMPARE(model->indexOf(tab2), 1);
        QCOMPARE(model->indexOf(nonAddedTab), -1);
        delete nonAddedTab;
    }

private:
    void moveTabs(int from, int to, bool moved, bool indexChanged, int newIndex)
    {
        QSignalSpy spyMoved(model, SIGNAL(rowsMoved(const QModelIndex&, int, int, const QModelIndex&, int)));
        QSignalSpy spyIndex(model, SIGNAL(currentIndexChanged()));
        QSignalSpy spyTab(model, SIGNAL(currentTabChanged()));

        model->move(from, to);
        QCOMPARE(spyMoved.count(), moved ? abs(from - to) : 0);
        if (moved) {
            QList<QVariant> argsFirst = spyMoved.first();
            QList<QVariant> argsLast = spyMoved.last();

            if (to > from) {
                QCOMPARE(argsFirst.at(1).toInt(), from);
                QCOMPARE(argsFirst.at(2).toInt(), from);
                QCOMPARE(argsFirst.at(4).toInt(), from + 2);

                QCOMPARE(argsLast.at(1).toInt(), to - 1);
                QCOMPARE(argsLast.at(2).toInt(), to - 1);
                QCOMPARE(argsLast.at(4).toInt(), to + 1);
            } else {
                QCOMPARE(argsFirst.at(1).toInt(), from);
                QCOMPARE(argsFirst.at(2).toInt(), from);
                QCOMPARE(argsFirst.at(4).toInt(), from - 1);

                QCOMPARE(argsLast.at(1).toInt(), to + 1);
                QCOMPARE(argsLast.at(2).toInt(), to + 1);
                QCOMPARE(argsLast.at(4).toInt(), to);
            }
        }
        QCOMPARE(spyIndex.count(), indexChanged ? 1 : 0);
        QCOMPARE(model->currentIndex(), newIndex);
        QVERIFY(spyTab.isEmpty());
    }

private Q_SLOTS:
    void shouldNotifyWhenMovingTabs()
    {
        for (int i = 0; i < 3; ++i) {
            model->add(createTab());
        }

        moveTabs(1, 1, false, false, 0);
        moveTabs(4, 1, false, false, 0);
        moveTabs(1, 4, false, false, 0);
        moveTabs(0, 2, true, true, 2);
        moveTabs(1, 0, true, false, 2);
        moveTabs(2, 1, true, true, 1);
        moveTabs(2, 0, true, true, 2);
        moveTabs(2, 1, true, true, 1);
        moveTabs(0, 2, true, true, 0);
    }
};

QTEST_MAIN(TabsModelTests)
#include "tst_TabsModelTests.moc"
